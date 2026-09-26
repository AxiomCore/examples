# Portable extension source fixtures

These are intentionally small, independent examples of the supported
source-authoring profiles. The shopping application remains the primary product
demo and uses Rust; this directory shows that TypeScript and Python lower to the
same typed ABI and capability broker without turning the app into a language
comparison.

Each source fixture contains an `AxiomDeps.toml` and authored source. Generated
declarations, bridges, package metadata, WASM, and locks belong under `.axiom/`
and are not committed here. These fixtures require a development build of the
CLI; they are not a released CLI quickstart.

The `dependencies/` examples show compatible sharing and an intentional exact-
version conflict. They use illustrative registry coordinates and are intended
for resolver testing, not installation from a public registry.
