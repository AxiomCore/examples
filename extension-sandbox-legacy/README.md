# Extension sandbox, legacy surface (kept on purpose)

This app is a regression fixture. It is written in the extension authoring
forms that X7 replaced, so that every deprecated form keeps building. **Do
not migrate it.** The migrated apps are `../axiom-shopping-app` and
`../axiom-project-management-app`.

| Deprecated form | Where | Replacement (X7) |
| --- | --- | --- |
| `use extension CheckoutRules from "checkout" export "recalculate"` and the call `CheckoutRules.recalculate(...)` | `main.acore` | `use extension checkout` and `checkout.recalculate(...)` |
| Long-form permissions `[extensions.checkout.permissions.ui-state.checkout]` | `AxiomDeps.toml` | `[extensions.checkout.permissions.ui.checkout]` |
| Explicit `exports = ["recalculate"]` | `AxiomDeps.toml` | omitted; derived from `#[export]` methods. Required here, because the guest uses a hand-written `axiom_extension()` factory, whose exports cannot be derived. |
| Positional `resume.outcome(0)` after a by-value `Effects::new().call(...)` chain | `extension-code/interaction.rs` | `let t = fx.push(op.call(input));` then `resume.get(t)` |

The old *generated selected names* (`Type_T`, `Step_e`, `Calls_c`, ...) exist
only for extensions with a selected `interface` file. None of the examples
has one, so they are not exercised here; `axiom-lib`
`tests/sdk_selected_names.rs` (`legacy_names_keep_their_old_meaning`) covers
them.

The Rust guest uses `axiom-extension-sdk` 0.1.5, where `ResumeContext::outcome`
is `#[deprecated(since = "0.1.5")]`. The SDK is not published yet, so
`Cargo.toml` points at the sibling `axiom-extension-sdk` checkout.

```sh
just check   # source-build the guest and check the UI
```

`../extension-sandbox` is the older raw-ABI (`Extension` trait) version of the
same app and is left unchanged as well.
