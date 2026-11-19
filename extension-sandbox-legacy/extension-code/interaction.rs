//! Legacy X7 surface, kept on purpose (see ../README.md). This guest uses the
//! positional `ResumeContext::outcome(i)` that X7a deprecated in favour of
//! typed tickets (`Effects::push` + `resume.get(ticket)`), and a hand-written
//! `axiom_extension()` factory, so its exports cannot be derived and stay
//! listed in AxiomDeps.toml. Do not migrate this file.
use crate::axiom_bindings::{operations, ui::Checkout};
use axiom_extension_sdk::prelude::*;
use axiom_extension_sdk::raw::{Extension, Field, Value};

#[derive(Default)]
struct CheckoutRules {
    pending: Option<Pending>,
}

struct Pending {
    checkout: Checkout,
    discount: u64,
}

fn record(fields: Vec<(&str, Value)>) -> Value {
    let mut fields: Vec<Field> = fields
        .into_iter()
        .map(|(name, value)| Field { name: name.into(), value })
        .collect();
    fields.sort_by(|left, right| left.name.cmp(&right.name));
    Value::Record(fields)
}

impl TypedExtension for CheckoutRules {
    fn invoke(&mut self, invocation: TypedInvocation) -> Result<ExtensionResponse> {
        let checkout = Checkout::from(&invocation)?;
        let subtotal = match invocation.input::<u64>() {
            Ok(subtotal) => subtotal,
            Err(_) => checkout.subtotal::<u64>()?,
        };
        let discount = (subtotal / 10).min(50);
        self.pending = Some(Pending { checkout, discount });
        let message = record(vec![
            ("fields", Value::Record(Vec::new())),
            ("message", Value::String("checkout discount calculated".into())),
        ]);
        // By-value chain: no ticket is kept, so the resume reads by position.
        let effects = Effects::new().call(operations::runtime_logging_info::<Value, Value>().call(message));
        Ok(ExtensionResponse::yield_for(effects))
    }

    fn resume(&mut self, resume: ResumeContext) -> Result<ExtensionResponse> {
        let pending = self
            .pending
            .take()
            .ok_or_else(|| SdkError::invalid_input("no pending calculation"))?;
        // Deprecated since SDK 0.1.5 (X7a): positional outcome instead of a ticket.
        let _logged: Value = resume.outcome(0)?;
        let output = record(vec![
            ("discount", Value::Unsigned(pending.discount)),
            ("status", Value::String("applied".into())),
        ]);
        Ok(ExtensionResponse::new(output).patch(
            pending
                .checkout
                .patch()
                .discount(pending.discount)
                .status("Applied by verified Rust WASM"),
        ))
    }
}

pub fn axiom_extension() -> Box<dyn Extension> {
    boxed_extension(CheckoutRules::default())
}
