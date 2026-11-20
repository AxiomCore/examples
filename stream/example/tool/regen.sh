#!/usr/bin/env bash
# Rebuild assets/axiom/stream.axiom from ../contract/main.acore and regenerate lib/axiom_generated.
# The contract is native Acore that describes the FastAPI server in ../test_server.py, so this
# works on Linux, macOS and Windows (Git Bash) without the FastAPI extractor.
set -euo pipefail
APP="$(cd "$(dirname "$0")/.." && pwd)"
AXIOM="${AXIOM:-axiom}"
(cd "$APP/../contract" && "$AXIOM" check main.acore && "$AXIOM" build main.acore --out "$APP/assets/axiom/stream.axiom")
mv -f "$APP/assets/axiom/stream.server.json" "$APP/../contract/backend.server.json" 2>/dev/null || true
cd "$APP"
flutter pub get
dart run axiom_flutter_generator:generate --config AxiomDeps.toml --out axiom_generated
