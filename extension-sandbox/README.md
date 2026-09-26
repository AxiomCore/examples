# Sandboxed Rust extension from Acore

This is the minimal authored extension application. The application source is
one Acore UI, one dependency/permission declaration, and one ordinary Rust
file in an author-chosen folder:

```text
main.acore
AxiomDeps.toml
extension-code/interaction.rs
```

The folder name `extension-code` has no special meaning. Axiom resolves it
from `AxiomDeps.toml`, generates a private Cargo crate and typed Rust bindings,
builds portable core WebAssembly, signs the local release inputs, resolves the
authority/package locks, and embeds the verified bytes for each target.

The extension reads only `checkout.subtotal`, makes one bounded
`logging.info` host call, then returns one atomic patch for `discount` and
`status`. It never receives a renderer object, state pointer, database handle,
filesystem access, network access, or ambient process authority.

## First build or source update

Generate the signed local release after changing Rust source or permissions:

```bash
cd examples/extension-sandbox
laxiom extensions source-release checkout \
  --deps AxiomDeps.toml \
  --application example.extensions.checkout
```

No Cargo project, ABI wrapper, package draft, signature file, or authority lock
is authored by the application. Generated output lives under `.axiom/` and
`AxiomExtensions.toml` is the reviewable workflow selected by normal run
commands. Axiom creates ignored, mode-`0600` local signing keys and reuses them,
so repeating an unchanged release does not churn signatures or locks.

## Run

```bash
laxiom run main.acore --target web
laxiom run main.acore --target android
laxiom run main.acore --target ios
```

Press **Calculate in Rust sandbox** once. The visible state should change from
`Waiting for sandbox` and discount `0` to `Applied by verified Rust WASM` and
discount `12`. Repeated presses should remain deterministic. On every target,
also confirm the screen stays responsive and the terminal reports no extension,
authority, or runtime error. Closing the target must not cause a late update.

## Inspect and validate

```bash
laxiom ui inspect extensions main.acore --target web
laxiom extensions inspect checkout --manifest AxiomExtensions.toml
laxiom extensions permissions checkout --manifest AxiomExtensions.toml
laxiom extensions graph --manifest AxiomExtensions.toml
laxiom extensions verify --manifest AxiomExtensions.toml
just check
```

`just check` validates all UI target compilations, the source/release identity,
authority inspection, path-escape denial, and the separate shared-source
isolation fixture. The fixture proves that two modules can compile the same
nested shared Rust source while retaining different module-local grants.

The older host-probe acceptance fixture is maintained privately; this public
example contains only the supported authored-source workflow.
