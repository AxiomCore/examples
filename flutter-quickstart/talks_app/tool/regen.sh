#!/usr/bin/env bash
# Rebuild the contract from ../talks-api/main.acore and regenerate the Dart
# client (quickstart steps 2 and 4). Works on Linux, macOS and Windows (Git Bash).
set -euo pipefail
cd "$(dirname "$0")/.."
AXIOM="${AXIOM:-axiom}"
(cd ../talks-api && "$AXIOM" check main.acore && "$AXIOM" build main.acore --out backend.axiom)
"$AXIOM" pull ../talks-api/backend.axiom --framework flutter --name talks --out lib/axiom_generated
# axiom pull records an absolute source path; keep the committed file portable.
tmp="$(mktemp)"
sed 's#^source = ".*/talks-api/backend.axiom"#source = "../talks-api/backend.axiom"#' AxiomDeps.toml > "$tmp"
mv "$tmp" AxiomDeps.toml
