#!/usr/bin/env bash
# Rebuild assets/axiom/auth_obs_test.axiom from ../axiom.acore and regenerate lib/axiom_generated.
# ../axiom.acore amends a FastAPI app, so `axiom build` needs the FastAPI extractor
# (`axiom install --module fastapi-extractor`); CLI 0.156 runs extractors on macOS only.
set -euo pipefail
APP="$(cd "$(dirname "$0")/.." && pwd)"
AXIOM="${AXIOM:-axiom}"
(cd "$APP/.." && "$AXIOM" build axiom.acore --out "$APP/assets/axiom/auth_obs_test.axiom")
cd "$APP"
flutter pub get
dart run axiom_flutter_generator:generate --config AxiomDeps.toml --out axiom_generated
