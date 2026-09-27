#!/usr/bin/env python3
"""Fetch committed Rust extension dependencies before the CLI's offline build."""

from __future__ import annotations

from pathlib import Path
import subprocess
import tomllib


ROOT = Path(__file__).resolve().parents[1]


def manifests(root: Path = ROOT) -> list[Path]:
    found = []
    for source in sorted(root.rglob("main.acore")):
        deps = source.parent / "AxiomDeps.toml"
        cargo = source.parent / "Cargo.toml"
        if not deps.is_file() or not cargo.is_file():
            continue
        document = tomllib.loads(deps.read_text(encoding="utf-8"))
        if document.get("extensions"):
            lock = source.parent / "Cargo.lock"
            if not lock.is_file():
                raise RuntimeError(f"Rust extension project has no committed lockfile: {source.parent}")
            found.append(cargo)
    return found


def main() -> None:
    projects = manifests()
    if not projects:
        raise RuntimeError("No Rust extension example projects found")
    for manifest in projects:
        print(f"Fetching locked extension SDK for {manifest.parent.relative_to(ROOT)}", flush=True)
        subprocess.run(["cargo", "fetch", "--locked", "--manifest-path", str(manifest)],
                       check=True)


if __name__ == "__main__":
    main()
