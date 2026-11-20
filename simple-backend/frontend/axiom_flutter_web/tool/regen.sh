#!/usr/bin/env bash
# Rebuild assets/axiom/py-example.axiom from ../../backend/py-example/axiom.acore and
# regenerate lib/axiom_generated. The contract amends a FastAPI app, so `axiom build`
# needs the FastAPI extractor (`axiom install --module fastapi-extractor`) with the
# backend's Python dependencies importable; CLI 0.156 runs extractors on macOS only.
set -euo pipefail
APP="$(cd "$(dirname "$0")/.." && pwd)"
AXIOM="${AXIOM:-axiom}"
(cd "$APP/../../backend/py-example" && "$AXIOM" build axiom.acore --out "$APP/assets/axiom/py-example.axiom")
cd "$APP"
flutter pub get
dart run axiom_flutter_generator:generate --config AxiomDeps.toml --out axiom_generated
