# Portable extension source fixtures

These are intentionally small, independent examples of the supported
source-authoring profiles. The shopping application remains the primary product
demo and uses Rust; this directory shows that TypeScript and Python lower to the
same typed ABI and capability broker without turning the app into a language
comparison.

The TypeScript and Python fixtures have ordinary package manifests and locked
local dependencies on the sibling public `axiom-extension-sdk` checkout.
`boundary.acore` supplies the cart state schema for generated typed selectors.
Generated declarations, virtual environments, and WASM remain untracked; the
package-manager lockfiles are committed. Use the root examples README's
extension setup command to install the SDK and refresh editor bindings. These
are source and typing fixtures, not a claim that the currently released CLI can
run their WASM modules on a hosted runner.

The `dependencies/` examples show compatible sharing and an intentional exact-
version conflict. They use illustrative registry coordinates and are intended
for resolver testing, not installation from a public registry.
