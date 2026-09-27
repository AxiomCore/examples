#!/usr/bin/env python3
"""Install published extension SDKs and type-check every live example."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tomllib


ROOT = Path(__file__).resolve().parents[1]
RUST = (
    ("axiom-shopping-app/frontend", "pricing"),
    ("axiom-project-management-app/frontend", "risk"),
    ("extension-sandbox", "checkout"),
)
MANAGED = (
    (*RUST[0], "rust"),
    (*RUST[1], "rust"),
    (*RUST[2], "rust"),
    ("axiom-extension-language-samples/typescript", "pricing", "typescript"),
    ("axiom-extension-language-samples/python", "pricing", "python"),
)


def run(*args: str, cwd: Path = ROOT) -> None:
    print("+", " ".join(args), flush=True)
    subprocess.run(args, cwd=cwd, check=True)


def check_registry_lock(project: Path, language: str) -> None:
    """Reject local-path SDKs even if they report the expected version."""
    if language == "rust":
        manifest = tomllib.loads((project / "Cargo.toml").read_text())
        lock = tomllib.loads((project / "Cargo.lock").read_text())
        if manifest["dependencies"].get("axiom-extension-sdk") != "=0.1.0":
            raise RuntimeError(f"{project}: Rust SDK must pin crates.io version =0.1.0")
        for name, version in (("axiom-extension-abi", "1.0.0"),
                              ("axiom-extension-sdk-derive", "0.1.0"),
                              ("axiom-extension-sdk", "0.1.0")):
            matches = [item for item in lock["package"] if item["name"] == name]
            if (len(matches) != 1 or matches[0]["version"] != version
                    or not matches[0].get("source", "").startswith("registry+")
                    or not matches[0].get("checksum")):
                raise RuntimeError(f"{project}: {name}@{version} must be locked to crates.io")
    elif language == "typescript":
        manifest = json.loads((project / "package.json").read_text())
        lock = json.loads((project / "package-lock.json").read_text())
        package = lock["packages"].get("node_modules/@axiomcore/extension-sdk", {})
        if (manifest.get("devDependencies", {}).get("@axiomcore/extension-sdk") != "0.1.0"
                or lock["packages"][""].get("devDependencies", {}).get("@axiomcore/extension-sdk") != "0.1.0"
                or package.get("version") != "0.1.0"
                or not package.get("resolved", "").startswith("https://registry.npmjs.org/@axiomcore/extension-sdk/")
                or not package.get("integrity")):
            raise RuntimeError(f"{project}: TypeScript SDK must be locked to npm 0.1.0")
    elif language == "python":
        manifest = tomllib.loads((project / "pyproject.toml").read_text())
        lock = tomllib.loads((project / "uv.lock").read_text())
        packages = [item for item in lock["package"] if item["name"] == "axiom-extension-sdk"]
        if ("axiom-extension-sdk==0.1.0" not in manifest["project"]["dependencies"]
                or "axiom-extension-sdk" in manifest.get("tool", {}).get("uv", {}).get("sources", {})
                or len(packages) != 1 or packages[0]["version"] != "0.1.0"
                or packages[0].get("source", {}).get("registry") != "https://pypi.org/simple"
                or not packages[0].get("wheels")):
            raise RuntimeError(f"{project}: Python SDK must be locked to PyPI 0.1.0")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk-root", type=Path, default=ROOT.parent / "axiom-extension-sdk",
                        help="checkout containing the setup helper, not a package source")
    parser.add_argument("--cli", default="axiom")
    args = parser.parse_args()
    sdk = args.sdk_root.resolve(strict=True)
    setup = sdk / "scripts/setup_project.py"
    if not setup.is_file():
        parser.error(f"SDK setup script is missing: {setup}")

    for path, alias, _language in MANAGED:
        project = ROOT / path
        check_registry_lock(project, _language)
        common = (str(project), alias, "--cli", args.cli)
        run(sys.executable, str(setup), *common)
        run(sys.executable, str(setup), *common, "--check")

    for path, _alias in RUST:
        run("cargo", "check", "--locked", "--offline", "--examples",
            "--manifest-path", str(ROOT / path / "Cargo.toml"))

    typescript = ROOT / "axiom-extension-language-samples/typescript"
    run(str(typescript / "node_modules/.bin/tsc"), "--noEmit", "--project",
        str(typescript / "tsconfig.json"))

    python = ROOT / "axiom-extension-language-samples/python"
    run(str(python / ".venv/bin/python"), "-m", "compileall", "-q", "pricing.py", cwd=python)

    for project in (typescript, python):
        run(args.cli, "ui", "check", "boundary.acore", "--target", "web", cwd=project)

    print("Extension SDK dependency and editor checks passed for all five live examples.")


if __name__ == "__main__":
    main()
