#!/usr/bin/env python3
"""Build the X7-migrated extension apps and compare their outputs with goldens.

For each variant (the shopping app, and the project-management app with each
of its Rust, TypeScript and Python profiles) this script works on a temporary
copy of the app, so the checkout is never modified:

1. `axiom run main.acore --target web --once` (backend contract, extension
   source build, UI lock, signed local release workflow);
2. `axiom extensions source-build` for every target, `axiom extensions
   interface`, `axiom ui inspect extensions` for web/android/ios;
3. the golden harness (`scripts/x7-golden/harness`), which loads the signed
   release exactly as `axiom extensions run` does and runs the scenarios in
   `scripts/x7-golden/scenarios/` through the real kernel and host: output,
   patches, wire digests, host/broker/state audit and the UI state after the
   commit.

It then compares the normalised results with `scripts/x7-golden/golden/`.
Signing keys are generated per run, so key-dependent digests (authority
locks, signed documents) are masked; module digests are compared only with
`--strict-modules`: they depend on the exact toolchain (not on the checkout or
SDK location: the build stages a path-pinned SDK and remaps its paths).

The Rust guests pin `axiom-extension-sdk` through a relative path dependency on
the sibling SDK checkout (0.1.5 is unpublished). The temporary copy no longer
sits beside that checkout, so the path is rewritten to the absolute `--sdk-root`
location (outside the project, which the source build supports); `Cargo.lock`
is unchanged by this (path packages carry no source line), which is checked.

Usage:
  scripts/verify_x7_golden.py --cli <axiom> --harness <harness-binary> \\
      [--sdk-root ../axiom-extension-sdk] [--variant shop ...] [--update]

TypeScript/Python variants need the pinned tools in AXIOM_TYPESCRIPT_TSC,
AXIOM_TYPESCRIPT_ESBUILD, AXIOM_TYPESCRIPT_JAVY and AXIOM_PYTHON_COMPILER;
the SDK comes from AXIOM_EXTENSION_SDK_DEVELOPMENT_ROOT (set to --sdk-root
when unset; its typescript/ must be built).
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "scripts/x7-golden/golden"
SCENARIOS = ROOT / "scripts/x7-golden/scenarios"
WORKSPACE_INPUT = {"active_projects": 3, "blocked_tasks": 2, "completed_tasks": 20, "id": "northstar",
                   "team_members": 8, "total_tasks": 30, "week_label": "Sprint 14",
                   "workspace_name": "Northstar Studio"}
VARIANTS = {
    "shop": ("axiom-shopping-app", None, "pricing", "shopping-pricing.json"),
    "pm-rust": ("axiom-project-management-app", "rust", "risk", "project-management-risk.json"),
    "pm-typescript": ("axiom-project-management-app", "typescript", "risk", "project-management-risk.json"),
    "pm-python": ("axiom-project-management-app", "python", "risk", "project-management-risk.json"),
}
# Digests that depend on the per-run signing keys.
KEY_DEPENDENT = {"authoritySha256", "effectiveAuthoritySha256", "grantSha256", "requestSha256",
                 "targetPolicySha256", "packageLockSha256", "effectiveSha256"}
MODULE_DEPENDENT = {"moduleSha256", "resultWireSha256", "resultWireBytes"}


def run(cmd: list[str], cwd: Path, timeout: int = 1800) -> str:
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f"{' '.join(cmd)} failed ({result.returncode}) in {cwd}:\n{result.stderr[-4000:]}")
    return result.stdout


def mask(value, strict_modules: bool):
    if isinstance(value, dict):
        out = {}
        for key, item in value.items():
            if key in KEY_DEPENDENT:
                out[key] = "<key-dependent>"
            elif key in MODULE_DEPENDENT and not strict_modules:
                out[key] = "<module>"
            else:
                out[key] = mask(item, strict_modules)
        return out
    if isinstance(value, list):
        return [mask(item, strict_modules) for item in value]
    return value


def prepare(app: str, sdk_root: Path, temp: Path) -> Path:
    copy = temp / app
    shutil.copytree(ROOT / app, copy, ignore=shutil.ignore_patterns(".axiom", "target", "node_modules", ".venv",
                                                                        "AxiomDeps.lock", "AxiomExtensions.toml",
                                                                        "AxiomPackages.lock", "*.axiom"))
    frontend = copy / "frontend"
    manifest = frontend / "Cargo.toml"
    text = manifest.read_text()
    pinned = re.search(r'path = "([^"]*axiom-extension-sdk/rust/sdk)"', text)
    if pinned:
        manifest.write_text(text.replace(pinned.group(0), f'path = "{sdk_root / "rust/sdk"}"'))
        lock = (frontend / "Cargo.lock").read_bytes()
        run(["cargo", "metadata", "--locked", "--offline", "--format-version", "1"], frontend)
        if (frontend / "Cargo.lock").read_bytes() != lock:
            raise RuntimeError("re-pointing the SDK path changed Cargo.lock")
    return frontend


def capture(variant: str, cli: str, harness: str, sdk_root: Path, strict: bool) -> dict:
    app, profile, alias, scenarios = VARIANTS[variant]
    with tempfile.TemporaryDirectory(prefix="axiom-x7-golden-") as temp:
        frontend = prepare(app, sdk_root, Path(temp))
        if profile:
            shutil.copy(frontend / f"profiles/{profile}.toml", frontend / "AxiomDeps.toml")
        run([cli, "run", "main.acore", "--target", "web", "--once"], frontend)
        modules = {}
        for target in ("web", "android", "ios", "server"):
            built = json.loads(run([cli, "extensions", "source-build", alias, "--target", target], frontend))
            modules[target] = built["moduleSha256"]
        interface = frontend / "interface.json"
        run([cli, "extensions", "interface", alias, "--out", str(interface)], frontend)
        bindings = {}
        for target in ("web", "android", "ios"):
            view = json.loads(run([cli, "ui", "inspect", "extensions", "main.acore", "--target", target,
                                   "--lock", ".axiom/dev/axiom.ui.lock.json"], frontend))
            bindings[target] = view
        # The build records derived exports in the generated `.axiom/AxiomDeps.lock`
        # (the historical `<frontend>/AxiomDeps.lock` is still read as a fallback).
        lock = next((p for p in (frontend / ".axiom/AxiomDeps.lock", frontend / "AxiomDeps.lock") if p.is_file()),
                    frontend / ".axiom/AxiomDeps.lock")
        derived = json.loads(lock.read_text()).get("extensionExports", {}) if lock.is_file() else {}
        golden = json.loads(run([harness, str(SCENARIOS / scenarios), str(frontend / "AxiomExtensions.toml")],
                                frontend))
        return mask({
            "format": "axiom-examples-x7-golden-record/v1",
            "variant": variant,
            "moduleSha256": modules,
            "interface": json.loads(interface.read_text()),
            "derivedExports": {name: entry["exports"] for name, entry in derived.items()},
            "uiExtensionBindings": bindings,
            "scenarios": golden,
        }, strict)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--cli", required=True)
    parser.add_argument("--harness", required=True, help="built scripts/x7-golden/harness binary")
    parser.add_argument("--sdk-root", type=Path, default=ROOT.parent / "axiom-extension-sdk")
    parser.add_argument("--variant", action="append", choices=sorted(VARIANTS))
    parser.add_argument("--strict-modules", action="store_true",
                        help="also require identical module bytes (same toolchain and location as the goldens)")
    parser.add_argument("--update", action="store_true", help="rewrite the goldens")
    args = parser.parse_args()
    sdk_root = args.sdk_root.resolve(strict=True)
    os.environ.setdefault("AXIOM_EXTENSION_SDK_DEVELOPMENT_ROOT", str(sdk_root))
    failures = 0
    for variant in args.variant or list(VARIANTS):
        record = capture(variant, args.cli, args.harness, sdk_root, True)
        path = GOLDEN / f"{variant}.json"
        if args.update:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(record, indent=1, sort_keys=True, ensure_ascii=False) + "\n")
            print(f"updated {path.relative_to(ROOT)}")
            continue
        expected = json.loads(path.read_text())
        if not args.strict_modules:
            expected, record = mask(expected, False), mask(record, False)
        if expected == record:
            print(f"PASS {variant}")
        else:
            failures += 1
            print(f"FAIL {variant}: differs from {path.relative_to(ROOT)}")
            for key in sorted(set(expected) | set(record)):
                if expected.get(key) != record.get(key):
                    print(f"  - {key}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
