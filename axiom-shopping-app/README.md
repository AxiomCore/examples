# Minimal Acore shopping app

This example keeps each trust boundary visible:

- `backend/axiom.acore` owns the product and order contract plus stateful local mocks.
- `frontend/main.acore` owns imports, application authority, global styles, and
  the route table.
- `frontend/pages/` and `frontend/components/` contain first-class local Acore
  modules resolved at compile time.
- `frontend/styles/` owns typed tokens, layout, motion, responsive rules, and
  component-scoped presentation imported by `main.acore`.
- `frontend/AxiomDeps.toml` v2 imports the backend contract, registers the Rust source, and grants a narrow cart-state capability to the sandbox. Third-party build dependencies and runtime permissions remain separate tables.
- `frontend/sandbox/member_pricing.rs` contains imperative loyalty pricing compiled to sandboxed WASM.

The frontend never receives a database handle. The CLI builds the local backend contract as a development dependency, while the Rust module receives only the authorized cart snapshot and returns an atomic patch that the host validates.

The UI imports five local presentation components—`StoreHeader`, `StoreHero`,
`CatalogHeading`, `ProductCard`, and `BagTotals`—from `frontend/components/`.
`Home` lives in `frontend/pages/home.acore` and visibly owns page state,
contract operations, extension invocation, checkout actions, pending state,
and errors. Both `.acore` and `.acss` dependencies participate in the graph
revision, live reload, Inspector graph, and exact source evidence. They are
compile-time inputs only; target runtimes never load source files.

`Home` also demonstrates the concise authoring surface: `state cart { ... }`
maps directly to exact `ui-state.cart` capability paths, and one-expression
actions lower to the same validated action IR as block actions. `AppScreen`,
`Section`, `ResponsiveGrid`, `AsyncBoundary`, and `ActionButton` are versioned
standard component contracts whose authored and expanded behavior is visible
in Inspector. They do not add hidden network, retry, or state behavior.

## Run the app

No preparation command, fixture JSON, or explicit lock path is required. Start the Acore backend service in one terminal:

```sh
just backend
```

The current Acore service implementation intentionally shares the deterministic runtime with mock mode. To select the explicitly labelled mock workflow with verbose request diagnostics instead:

```sh
just mock
```

Then launch one frontend target in another terminal. `laxiom run` builds stale local contracts, resolves the development lock, compiles and verifies the Rust WASM module, and reuses its cache on later runs:

```sh
just web
just android
just ios
```

The portable base URL is `http://127.0.0.1:8080`. Axiom translates it for the Android Emulator while iOS Simulator and Web use the host loopback.

The product query uses the contract's `stale_while_revalidate` cache policy. The first successful launch seeds the target's persistent cache. Every later launch renders that local product list immediately, starts a backend refresh in the background, and replaces the list when the fresh response arrives. Each target owns its own cache, so Web, Android, and iOS each need one successful request before their first local-first launch.

An optional all-target compile check uses the same automatic preparation path:

```sh
just check
```

Review the deterministic application graph, extension authority, dependency
policy, and release readiness without opening generated locks:

```sh
just audit
just release-check
just inspect
```

The Inspector dashboard connects the visible UI and backend operations to the
local Acore modules, imported styles, grouped cart state, contract cache policy,
typed Rust export, generated interface, WASM artifact, requested authority,
effective target policy, and runtime audits. The optional remote explanation
planner never replaces these deterministic facts.

## What to validate

1. The catalog loads four products from the backend contract. Stop and relaunch the frontend: the saved catalog should render before the background request completes, then update in place without a loading placeholder.
2. **Apply member price** changes the total from `$237.00` to `$201.45`, shows a `−$35.55` saving, and reports that verified Rust WASM applied it.
3. **Checkout securely** calls the typed `create_order` mutation; the temporary progress/error UI is driven by the contract runtime.
4. Generated contracts, development locks, WASM artifacts and local signing material stay under ignored build paths; developers maintain only the Acore, Rust and manifest sources.
