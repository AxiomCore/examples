#!/usr/bin/env python3
"""Install digest-verified public macOS ARM64 release tools for example CI.

GitHub's latest-release endpoint is unsuitable here: UI hosts, runtimes and
packages share the same release repository and may be newer than the CLI.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import tarfile
import urllib.request


API = "https://api.github.com/repos/AxiomCore/AxiomCore/releases"
TOOLS = (
    (re.compile(r"v(\d+)\.(\d+)\.(\d+)$"), "axiom-macos-arm64.tar.gz", "axiom"),
    (re.compile(r"extractor-fastapi-v(\d+)\.(\d+)\.(\d+)$"),
     "axiom-fastapi-macos-arm64", "axiom-fastapi-extractor"),
    (re.compile(r"extractor-go-(\d+)\.(\d+)\.(\d+)\.(\d+)$"),
     "axiom-go-extractor-macos-arm64", "axiom-go-extractor"),
)


def request(url: str) -> bytes:
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "axiom-examples-ci"}
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=60) as response:
        return response.read()


def releases() -> list[dict]:
    result = []
    for page in range(1, 11):
        batch = json.loads(request(f"{API}?per_page=100&page={page}"))
        result.extend(batch)
        if len(batch) < 100:
            return result
    raise RuntimeError("Too many releases; increase the pagination limit")


def select(release_list: list[dict], pattern: re.Pattern, asset_name: str) -> tuple[dict, dict]:
    matches = []
    for release in release_list:
        match = pattern.fullmatch(release.get("tag_name", ""))
        if release.get("draft") or release.get("prerelease") or match is None:
            continue
        asset = next((item for item in release.get("assets", []) if item["name"] == asset_name), None)
        if asset is not None:
            matches.append((tuple(map(int, match.groups())), release, asset))
    if not matches:
        raise RuntimeError(f"No stable release contains {asset_name}")
    _, release, asset = max(matches, key=lambda item: item[0])
    return release, asset


def verified_asset(asset: dict) -> bytes:
    digest = asset.get("digest", "")
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        raise RuntimeError(f"Missing SHA-256 digest for {asset['name']}")
    data = request(asset["browser_download_url"])
    if hashlib.sha256(data).hexdigest() != digest.removeprefix("sha256:"):
        raise RuntimeError(f"Digest mismatch for {asset['name']}")
    return data


def install(destination: Path, name: str, data: bytes) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    path = destination / name
    path.write_bytes(data)
    path.chmod(0o755)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bin-dir", type=Path, required=True)
    parser.add_argument("--extractor-dir", type=Path, required=True)
    args = parser.parse_args()
    available = releases()
    for index, (pattern, asset_name, binary_name) in enumerate(TOOLS):
        release, asset = select(available, pattern, asset_name)
        data = verified_asset(asset)
        if index == 0:
            with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
                members = [member for member in archive.getmembers()
                           if member.isfile() and Path(member.name).name == "axiom"]
                if len(members) != 1:
                    raise RuntimeError("CLI archive must contain exactly one axiom binary")
                data = archive.extractfile(members[0]).read()
        install(args.bin_dir if index == 0 else args.extractor_dir, binary_name, data)
        print(f"Installed {binary_name} from {release['tag_name']} ({asset['digest']})")
    github_path = os.environ.get("GITHUB_PATH")
    if github_path:
        with open(github_path, "a", encoding="utf-8") as path_file:
            path_file.write(f"{args.bin_dir}\n")


if __name__ == "__main__":
    main()
