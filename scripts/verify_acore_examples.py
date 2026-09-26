#!/usr/bin/env python3
"""Run every Acore backend and web frontend entry point with the released CLI."""

from __future__ import annotations

import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_ROOTS = {
    "axiom-extension-language-samples", "axiom-project-management-app",
    "axiom-shopping-app", "axiom-ui-task-app", "demo-app", "domain-commerce",
    "domain-inference-fastapi", "domain-support", "extension-sandbox",
    "native-ui-first-render", "observability-and-auth", "offline-first-feed",
    "package-dependencies", "realtime-chat", "rpc", "security-mode-v1",
    "simple-backend", "stream", "ui-feature-gallery", "ui-interaction-demos",
}


def run(label: str, directory: Path, *args: str, expect: str | None = None) -> bool:
    env = dict(os.environ)
    env["CI"] = "1"
    # Compilation is local; this explicitly selects the CLI's local profile
    # without requiring a production private-alpha referral in public CI.
    env.setdefault("AXIOM_CLOUD_URL", "http://127.0.0.1:8000")
    try:
        binary = env.get("AXIOM_BIN", "axiom")
        result = subprocess.run([binary, *args], cwd=directory, env=env,
                                text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=180, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        print(f"FAIL {label}: {error}", flush=True)
        return False
    passed = (result.returncode == 0) if expect is None else (
        result.returncode != 0 and expect in result.stdout)
    print(f"{'PASS' if passed else 'FAIL'} {label}: axiom {' '.join(args)}", flush=True)
    if not passed:
        print(result.stdout[-4000:], flush=True)
    return passed


def smoke_server(label: str, directory: Path, source: str, *, web: bool) -> bool:
    with socket.socket() as reservation:
        reservation.bind(("127.0.0.1", 0))
        port = reservation.getsockname()[1]
    env = dict(os.environ)
    env["CI"] = "1"
    env.setdefault("AXIOM_CLOUD_URL", "http://127.0.0.1:8000")
    if web:
        env["AXIOM_UI_WEB_PORT"] = str(port)
        command = [env.get("AXIOM_BIN", "axiom"),
                   *( ["packages", "run"] if label == "package-dependencies/main.acore" else ["run"] ),
                   source, "--target", "web"]
        if label == "package-dependencies/main.acore":
            command.extend(["--package-lock", "AxiomPackages.lock"])
        probe = "/__axiom/app.json"
    else:
        command = [env.get("AXIOM_BIN", "axiom"), "run", source, "--mode", "mock",
                   "--port", str(port)]
        probe = "/_axiom/health"
    process = subprocess.Popen(command, cwd=directory, env=env, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True)
    success = False
    try:
        deadline = time.monotonic() + 45
        while time.monotonic() < deadline and process.poll() is None:
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{port}{probe}", timeout=2) as reply:
                    success = reply.status == 200 and bool(reply.read())
                    break
            except (urllib.error.URLError, TimeoutError):
                time.sleep(0.3)
    finally:
        process.terminate() if process.poll() is None else None
        try:
            output, _ = process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            output, _ = process.communicate()
    print(f"{'PASS' if success else 'FAIL'} {label}: {'web' if web else 'mock'} server HTTP probe", flush=True)
    if not success:
        print(output[-4000:], flush=True)
    return success


def main() -> int:
    roots = {path.name for path in ROOT.iterdir() if path.is_dir() and not path.name.startswith(".")
             and path.name != "scripts"}
    if roots != EXPECTED_ROOTS:
        print(f"Example coverage changed: added={sorted(roots - EXPECTED_ROOTS)}, "
              f"removed={sorted(EXPECTED_ROOTS - roots)}", flush=True)
        return 1
    results = []
    for source in sorted(ROOT.rglob("axiom.acore")):
        label = str(source.relative_to(ROOT))
        compiled = run(label, source.parent, "build", source.name)
        results.append(compiled)
        if compiled:
            results.append(smoke_server(label, source.parent, source.name, web=False))
    for source in sorted(ROOT.rglob("main.acore")):
        label = str(source.relative_to(ROOT))
        command = ("packages", "run") if label == "package-dependencies/main.acore" else ("run",)
        extra = ("--package-lock", "AxiomPackages.lock") if label == "package-dependencies/main.acore" else ()
        compiled = run(label, source.parent, *command, source.name, "--target", "web", "--once", *extra)
        results.append(compiled)
        if compiled:
            results.append(smoke_server(label, source.parent, source.name, web=True))
    for source in sorted(ROOT.glob("ui-feature-gallery/**/web-*.acore")):
        results.append(run(str(source.relative_to(ROOT)), source.parent, "run", source.name,
                           "--target", "web", "--once"))
    for source in ("commerce-v1.acore", "commerce-v2.acore"):
        results.append(run(f"domain-commerce/{source}", ROOT / "domain-commerce",
                           "domain", "validate", source))
    results.append(run("domain-commerce/semantic-diff", ROOT / "domain-commerce",
                       "diff", "commerce-v1.acore", "commerce-v2.acore", "--format", "semantic"))
    results.append(run("domain-support/support-v1.acore", ROOT / "domain-support",
                       "domain", "validate", "support-v1.acore"))
    results.append(run("security-mode-v1/safe", ROOT / "security-mode-v1",
                       "security", "check", "axiom.acore"))
    results.append(run("security-mode-v1/expected-strict-rejection", ROOT / "security-mode-v1",
                       "security", "check", "axiom.unsafe.acore", expect="AXSEC-001"))
    # Language-source extension fixtures require an unpublished development
    # CLI. Their files are content-audited separately; they are not silently
    # treated as released-CLI smoke tests.
    extension = ROOT / "axiom-extension-language-samples"
    results.append(all((extension / name).is_file() for name in (
        "python/pricing.py", "typescript/pricing.ts",
        "dependencies/shared/extension.rs", "dependencies/conflict/extension.rs")))
    print(f"Extension source fixtures present: {results[-1]}")
    print(f"Acore checks: {sum(results)}/{len(results)} passed", flush=True)
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
