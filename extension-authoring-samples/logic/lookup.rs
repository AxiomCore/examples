//! Lookup extension used by the extension documentation: one yield with two
//! host calls, read back with typed tickets. `lookup` yields a sequential
//! plan; `lookup_group` yields the same two calls as an effect group.
#![deny(deprecated)]
use crate::axiom_bindings::operations::{
    contract_catalog_query_price as price_of, contract_catalog_query_stock as stock_of,
};
use axiom_extension_sdk::prelude::*;
use axiom_extension_sdk::abi::EffectGroupMode;
use axiom_extension_sdk::{boxed_extension, EffectGroup, Effects, Extension, ResumeContext, Ticket, TypedExtension};

/// The same constant as the TypeScript and Python editions, whose resume
/// receives no input.
const FEATURED: &str = "featured";

#[derive(AxiomType)]
struct Item {
    in_stock: bool,
    price_label: String,
}

struct Pending {
    price: Ticket<Cents>,
    stock: Ticket<u64>,
}

#[derive(Default)]
struct Lookup {
    pending: Option<Pending>,
}

impl TypedExtension for Lookup {
    fn invoke(&mut self, invocation: TypedInvocation) -> Result<ExtensionResponse> {
        match invocation.export() {
            "lookup" => {
                let mut fx = Effects::new();
                let price = fx.push(price_of::<String, Cents>().call(String::from(FEATURED)));
                let stock = fx.push(stock_of::<String, u64>().call(String::from(FEATURED)));
                self.pending = Some(Pending { price, stock });
                Ok(ExtensionResponse::yield_for(fx))
            }
            "lookup_group" => {
                // Both branches may run at once; outcomes keep declaration order.
                let mut group = EffectGroup::new(EffectGroupMode::Collect, 2);
                let price = group.push("price", price_of::<String, Cents>().call(String::from(FEATURED)));
                let stock = group.push("stock", stock_of::<String, u64>().call(String::from(FEATURED)));
                self.pending = Some(Pending { price, stock });
                Ok(ExtensionResponse::yield_effect_group(group))
            }
            other => Err(SdkError::invalid_input(format!("unknown export `{other}`"))),
        }
    }

    fn resume(&mut self, resume: ResumeContext) -> Result<ExtensionResponse> {
        let pending = self.pending.take().ok_or_else(|| SdkError::invalid_input("no lookup is pending"))?;
        let price = resume.get(pending.price)?;
        let stock = resume.get(pending.stock)?;
        Ok(ExtensionResponse::new(Item { in_stock: stock > 0, price_label: price.as_currency() }))
    }
}

pub fn axiom_extension() -> Box<dyn Extension> {
    boxed_extension(Lookup::default())
}
