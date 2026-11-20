#!/usr/bin/env bash
# Rebuild assets/axiom/realtime-chat.axiom from ../../backend/go-chat/axiom.acore and
# regenerate lib/axiom_generated. The contract amends a Go server, so `axiom build`
# needs the Go extractor (`axiom install --module go-extractor`) and a Go toolchain;
# CLI 0.156 runs extractors on macOS only.
set -euo pipefail
APP="$(cd "$(dirname "$0")/.." && pwd)"
AXIOM="${AXIOM:-axiom}"
(cd "$APP/../../backend/go-chat" && "$AXIOM" build axiom.acore --out "$APP/assets/axiom/realtime-chat.axiom")
cd "$APP"
flutter pub get
dart run axiom_flutter_generator:generate --config AxiomDeps.toml --out axiom_generated
