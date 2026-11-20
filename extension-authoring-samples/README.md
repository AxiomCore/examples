# Extension authoring samples

The code samples of the AxiomCore extension documentation come from this
project. Each sample exists in Rust, TypeScript and Python and behaves the same
in all three.

| Alias | Language | Exports | Shows |
| --- | --- | --- | --- |
| `pricing` | Rust | `quote`, `apply_discount` | An async export with three effect rounds; a sync export that patches UI state with `Cents` and `Percentage`; exports derived from the source |
| `pricingts` | TypeScript | `quote`, `apply_discount` | The same, with `extension.export` and `Promise.all` |
| `pricingpy` | Python | `quote`, `apply_discount` | The same, with `async def` and `gather`, and a longer `deadlineMs` |
| `lookup` | Rust | `lookup`, `lookup_group` | One yield read back with typed tickets; the same calls as an effect group with group tickets |
| `lookupts` | TypeScript | `lookup` | Tickets with a rebuilt plan in the resume |
| `lookuppy` | Python | `lookup` | The same in Python |

`main.acore` calls `pricing.apply_discount` with the name-once `use extension`
form and a `writes` clause. `AxiomDeps.toml` uses the permission shorthand and
`[extensions.<alias>.budgets]`.

## Requirements

- An Axiom CLI release that accepts extension SDK 0.1.5.
- Rust: `wasm32-unknown-unknown`. `Cargo.toml` pins `axiom-extension-sdk`
  0.1.5; until 0.1.5 is on crates.io it is pinned by path to a checkout of the
  SDK repository next to this one.
- TypeScript and Python: `tsc` 7.0.2, `esbuild` 0.28.2, `javy` 9.1.0 and the
  TypeScript SDK 0.1.5; Python also needs Python 3.12.11 and the Python SDK
  0.1.5.

## Build and release

```sh
axiom dependencies check
for alias in pricing pricingts pricingpy lookup lookupts lookuppy; do
  axiom extensions source-release "$alias" --application example.extension.samples
done
axiom extensions verify
```

## Run

`axiom extensions run` uses a reference host that answers no contract queries,
so it can run `apply_discount` but not `quote` or `lookup`:

```sh
axiom extensions run pricing --export apply_discount --input 12000 --snapshot cart=scenarios/cart.json
```

`scripts/extension-docs-harness` in this repository runs every scenario in
`scenarios/` through the real host with a deterministic catalog and prints the
result, the effects per round and the UI state after the commit:

```sh
cargo run --release --manifest-path ../scripts/extension-docs-harness/Cargo.toml -- \
  scenarios/pricing.json AxiomExtensions.toml
```

Expected results (all three languages):

| Scenario | Result |
| --- | --- |
| `quote-in-stock` | `{"available": true, "label": "$106.99", "total_cents": 10699}` after three rounds |
| `quote-out-of-stock` | `{"available": false, "label": "Out of stock", "total_cents": 0}` after two rounds |
| `apply-discount` | `{"discount_cents": 1200, "total_cents": 10800}`, and the cart patched to the same values |
| `lookup-featured` | `{"in_stock": true, "price_label": "$49.99"}` |
