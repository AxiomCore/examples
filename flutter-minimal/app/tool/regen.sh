#!/usr/bin/env bash
# Rebuild the contract from ../api/main.acore and regenerate the Dart
# client . Works on Linux, macOS and Windows (Git Bash).
set -euo pipefail
cd "$(dirname "$0")/.."
AXIOM="${AXIOM:-axiom}"
(cd ../api && "$AXIOM" check main.acore && "$AXIOM" build main.acore --out backend.axiom)
"$AXIOM" pull ../api/backend.axiom --framework flutter --name minimal --out lib/axiom_generated
# axiom pull records an absolute source path; keep the committed file portable.
tmp="$(mktemp)"
sed 's#^source = ".*/api/backend.axiom"#source = "../api/backend.axiom"#' AxiomDeps.toml > "$tmp"
mv "$tmp" AxiomDeps.toml
