use axiom_extension_sdk::{
    abi::{EffectOutcome, EventBatch, ExtensionError, GuestMessage, Invocation, RequestId},
    completed, Extension,
};

mod shared;

struct Reader;

impl Extension for Reader {
    fn invoke(&mut self, request_id: RequestId, invocation: Invocation) -> GuestMessage {
        completed(request_id, shared::normalized(invocation.input))
    }

    fn resume(
        &mut self,
        request_id: RequestId,
        _: Vec<EffectOutcome>,
        _: Vec<EventBatch>,
    ) -> GuestMessage {
        completed(request_id, axiom_extension_sdk::abi::Value::Null)
    }

    fn cancel(&mut self, _: RequestId) -> Result<(), ExtensionError> {
        Ok(())
    }
}

pub fn axiom_extension() -> Box<dyn Extension> {
    Box::new(Reader)
}
