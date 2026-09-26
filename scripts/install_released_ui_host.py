#!/usr/bin/env python3
"""Install the newest signed public web UI host with authenticated API access.

The released CLI's automatic host lookup is unauthenticated, which can hit
GitHub's shared-runner API limit. Download release assets with the workflow
token, verify GitHub's SHA-256 digests, then let the CLI verify the signed
manifest and its selected web asset before registration.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess

from install_released_toolchain import releases, select, verified_asset


HOST_TAG = re.compile(r"ui-host-v(\d+)\.(\d+)\.(\d+)$")


def web_asset(manifest: dict, release: dict) -> dict:
    candidates = [item for item in manifest.get("assets", [])
                  if item.get("target") == "web"]
    if len(candidates) != 1:
        raise RuntimeError("Signed UI host manifest must have exactly one web asset")
    name = candidates[0].get("file", "")
    if not name or name.startswith(".") or Path(name).name != name:
        raise RuntimeError("Unsafe UI host asset name")
    match = next((item for item in release["assets"] if item["name"] == name), None)
    if match is None:
        raise RuntimeError(f"UI host release is missing {name}")
    return match


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bin", default="axiom")
    parser.add_argument("--download-dir", type=Path, required=True)
    args = parser.parse_args()

    release, manifest_asset = select(releases(), HOST_TAG, "host-manifest.json")
    manifest_bytes = verified_asset(manifest_asset)
    manifest = json.loads(manifest_bytes)
    signature_asset = next((item for item in release["assets"]
                            if item["name"] == "host-manifest.json.sig"), None)
    if signature_asset is None:
        raise RuntimeError("UI host release has no manifest signature")
    payloads = {
        "host-manifest.json": manifest_bytes,
        "host-manifest.json.sig": verified_asset(signature_asset),
    }
    asset = web_asset(manifest, release)
    payloads[asset["name"]] = verified_asset(asset)
    args.download_dir.mkdir(parents=True, exist_ok=True)
    for name, data in payloads.items():
        (args.download_dir / name).write_bytes(data)
    print(f"Installing signed web UI host from {release['tag_name']}", flush=True)
    subprocess.run([args.bin, "ui", "host", "install", "--target", "web",
                    "--release-manifest", str(args.download_dir / "host-manifest.json"),
                    "--non-interactive"], check=True)


if __name__ == "__main__":
    main()
