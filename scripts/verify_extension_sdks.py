#!/usr/bin/env python3
"""Install the public extension SDK checkout and type-check every live example."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys


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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk-root", type=Path, default=ROOT.parent / "axiom-extension-sdk")
    parser.add_argument("--cli", default="axiom")
    args = parser.parse_args()
    sdk = args.sdk_root.resolve(strict=True)
    setup = sdk / "scripts/setup_project.py"
    if not setup.is_file():
        parser.error(f"SDK setup script is missing: {setup}")

    for path, alias, _language in MANAGED:
        project = ROOT / path
        common = (str(project), alias, "--sdk-root", str(sdk), "--cli", args.cli)
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
