use axiom_extension_sdk::prelude::*;

#[derive(Default)]
struct Example;

#[extension]
impl Example {
    #[export]
    fn run(&mut self, invocation: TypedInvocation) -> Result<ExtensionResponse> {
        Ok(ExtensionResponse::new(invocation.input::<u64>()?))
    }
}
