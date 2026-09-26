#!/usr/bin/env bash
set -euo pipefail

AXIOM_BIN="${1:-laxiom}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

axiom() {
  "$AXIOM_BIN" "$@"
}

cd "$ROOT"

axiom extensions source-release checkout \
  --deps AxiomDeps.toml \
  --application example.extensions.checkout

for target in web android ios; do
  axiom ui check main.acore --target "$target"
done

axiom extensions verify --manifest AxiomExtensions.toml
axiom extensions inspect checkout --manifest AxiomExtensions.toml >/dev/null
axiom extensions permissions checkout --manifest AxiomExtensions.toml >/dev/null
axiom extensions graph --manifest AxiomExtensions.toml >/dev/null

SHARED="$ROOT/conformance/shared-source"
axiom extensions source-build reader \
  --deps "$SHARED/AxiomDeps.toml" \
  --out "$SHARED/.axiom/extensions" \
  --target web >"$TEMP_DIR/reader.json"
axiom extensions source-build writer \
  --deps "$SHARED/AxiomDeps.toml" \
  --out "$SHARED/.axiom/extensions" \
  --target web >"$TEMP_DIR/writer.json"

READER_LOCK="$(jq -r .lock "$TEMP_DIR/reader.json")"
WRITER_LOCK="$(jq -r .lock "$TEMP_DIR/writer.json")"
test "$(jq -r '.sourceFiles["logic/shared/mod.rs"]' "$READER_LOCK")" = \
  "$(jq -r '.sourceFiles["logic/shared/mod.rs"]' "$WRITER_LOCK")"
jq -e '.permissions.runtime == ["logging.info"]' "$READER_LOCK" >/dev/null
jq -e '.permissions.runtime == ["logging.warn"]' "$WRITER_LOCK" >/dev/null

if axiom extensions source-build escape \
  --deps "$ROOT/conformance/path-escape/AxiomDeps.toml" \
  --out "$ROOT/conformance/path-escape/.axiom/extensions" \
  --target web >/dev/null 2>&1; then
  echo "expected the path-escape fixture to be denied" >&2
  exit 1
fi

echo "Source-extension acceptance passed."
