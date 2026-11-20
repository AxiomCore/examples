#!/usr/bin/env bash
# Rebuild the contract from ../api/main.acore and regenerate lib/axiom_generated (any OS).
set -euo pipefail
cd "$(dirname "$0")/.."
AXIOM="${AXIOM:-axiom}"
(cd ../api && "$AXIOM" check main.acore && "$AXIOM" build main.acore --out backend.axiom)
"$AXIOM" pull ../api/backend.axiom --framework flutter --name api --out lib/axiom_generated
tmp="$(mktemp)"
sed 's#^source = ".*/api/backend.axiom"#source = "../api/backend.axiom"#' AxiomDeps.toml > "$tmp"
mv "$tmp" AxiomDeps.toml
