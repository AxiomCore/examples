use axiom_extension_sdk::{
    abi::{
        EffectOutcome, ErrorCode, EventBatch, ExtensionError, Field, GuestMessage, Invocation,
        RequestId, Value,
    },
    completed_with_changes, EffectPlanBuilder, Extension, UiPatchBuilder,
};
use crate::axiom_bindings::{
    runtime_logging_info, ui_checkout_write_discount_selector,
    ui_checkout_write_status_selector,
};

struct CheckoutRules {
    pending: Option<PendingCalculation>,
}

struct PendingCalculation {
    revision: u64,
    discount: u64,
}

struct Discount;
struct Status;

impl Extension for CheckoutRules {
    fn invoke(&mut self, request_id: RequestId, invocation: Invocation) -> GuestMessage {
        if invocation.export != "recalculate" {
            return failed(request_id, ErrorCode::InvalidInput, "unknown checkout export");
        }
        let Some(snapshot) = invocation
            .snapshots
            .iter()
            .find(|snapshot| snapshot.resource == "ui:checkout")
        else {
            return failed(request_id, ErrorCode::Denied, "authorized checkout snapshot is missing");
        };
        let Some(subtotal) = unsigned(&invocation.input)
            .or_else(|| field(&snapshot.value, "subtotal").and_then(unsigned))
        else {
            return failed(request_id, ErrorCode::InvalidInput, "subtotal must be a non-negative integer");
        };
        let discount = (subtotal / 10).min(50);
        self.pending = Some(PendingCalculation {
            revision: snapshot.revision,
            discount,
        });
        GuestMessage::Yielded {
            request_id,
            plan: EffectPlanBuilder::new()
                .call(
                    &runtime_logging_info,
                    record(vec![
                        (
                            "message",
                            Value::String("checkout discount calculated".into()),
                        ),
                        ("fields", Value::Record(Vec::new())),
                    ]),
                )
                .build(),
        }
    }

    fn resume(
        &mut self,
        request_id: RequestId,
        outcomes: Vec<EffectOutcome>,
        _: Vec<EventBatch>,
    ) -> GuestMessage {
        let Some(pending) = self.pending.take() else {
            return failed(request_id, ErrorCode::Protocol, "no pending calculation");
        };
        if outcomes.len() != 1 || outcomes[0].result.is_err() {
            return failed(request_id, ErrorCode::Host, "bounded logging call failed");
        }
        let discount = ui_checkout_write_discount_selector::<Discount>();
        let status = ui_checkout_write_status_selector::<Status>();
        let patch = UiPatchBuilder::new("checkout", pending.revision)
            .set(&discount, Value::Unsigned(pending.discount))
            .set(&status, Value::String("Applied by verified Rust WASM".into()))
            .build();
        completed_with_changes(
            request_id,
            record(vec![
                ("discount", Value::Unsigned(pending.discount)),
                ("status", Value::String("applied".into())),
            ]),
            vec![patch],
            vec![],
        )
    }

    fn cancel(&mut self, _: RequestId) -> Result<(), ExtensionError> {
        self.pending = None;
        Ok(())
    }

    fn shutdown(&mut self) {
        self.pending = None;
    }
}

fn field<'a>(value: &'a Value, name: &str) -> Option<&'a Value> {
    let Value::Record(fields) = value else { return None };
    fields.iter().find(|field| field.name == name).map(|field| &field.value)
}

fn unsigned(value: &Value) -> Option<u64> {
    match value {
        Value::Unsigned(value) => Some(*value),
        Value::Signed(value) if *value >= 0 => Some(*value as u64),
        _ => None,
    }
}

fn record(values: Vec<(&str, Value)>) -> Value {
    let mut fields: Vec<Field> = values
        .into_iter()
        .map(|(name, value)| Field { name: name.into(), value })
        .collect();
    fields.sort_by(|left, right| left.name.cmp(&right.name));
    Value::Record(fields)
}

fn failed(request_id: RequestId, code: ErrorCode, message: &str) -> GuestMessage {
    GuestMessage::Failed {
        request_id,
        error: ExtensionError {
            code,
            message: message.into(),
            retryable: false,
        },
    }
}

pub fn axiom_extension() -> Box<dyn Extension> {
    Box::new(CheckoutRules { pending: None })
}
