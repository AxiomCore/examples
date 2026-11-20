#!/usr/bin/env bash
# Rebuild the contract from ../feed-api/main.acore and regenerate the Dart
# client . Works on Linux, macOS and Windows (Git Bash).
set -euo pipefail
cd "$(dirname "$0")/.."
AXIOM="${AXIOM:-axiom}"
(cd ../feed-api && "$AXIOM" check main.acore && "$AXIOM" build main.acore --out backend.axiom)
"$AXIOM" pull ../feed-api/backend.axiom --framework flutter --name feed --out lib/axiom_generated
# axiom pull records an absolute source path; keep the committed file portable.
tmp="$(mktemp)"
sed 's#^source = ".*/feed-api/backend.axiom"#source = "../feed-api/backend.axiom"#' AxiomDeps.toml > "$tmp"
mv "$tmp" AxiomDeps.toml
