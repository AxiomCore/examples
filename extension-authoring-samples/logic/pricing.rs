//! Pricing extension used by the extension documentation. `quote` is an async
//! export that needs three effect rounds; `apply_discount` is a sync export
//! that proposes a UI patch.
#![deny(deprecated)]
use crate::axiom_bindings::operations::{
    contract_catalog_query_discount as discount_of, contract_catalog_query_price as price_of,
    contract_catalog_query_shipping as shipping_of, contract_catalog_query_stock as stock_of,
};
use crate::axiom_bindings::ui::Cart;
use axiom_extension_sdk::prelude::*;
use axiom_extension_sdk::try_join;

#[derive(AxiomType)]
struct Quote {
    available: bool,
    label: String,
    total_cents: Cents,
}

#[derive(AxiomType)]
struct Applied {
    discount_cents: Cents,
    total_cents: Cents,
}

#[derive(Default)]
struct Pricing;

#[extension]
impl Pricing {
    #[export]
    async fn quote(cx: &Cx, sku: String) -> Result<Quote> {
        // Round 1: one host call.
        let price: Cents = cx.call(price_of::<String, Cents>().call(sku.clone())).await?;
        // Round 2: two independent calls, sent together as one group.
        let (stock, discount) = try_join!(
            cx.call(stock_of::<String, u64>().call(sku.clone())),
            cx.call(discount_of::<String, Percentage>().call(sku.clone())),
        )
        .await?;
        if stock == 0 {
            return Ok(Quote { available: false, label: String::from("Out of stock"), total_cents: Cents::ZERO });
        }
        // Round 3: only reached when the item is in stock.
        let shipping: Cents = cx.call(shipping_of::<String, Cents>().call(sku)).await?;
        let discounted = price.checked_sub(discount.of(price)?)?;
        let total = discounted
            .value()
            .checked_add(shipping.value())
            .map(Cents::new)
            .ok_or_else(|| SdkError::invalid_input("total is out of range"))?;
        Ok(Quote { available: true, label: total.as_currency(), total_cents: total })
    }

    #[export]
    fn apply_discount(&mut self, invocation: TypedInvocation) -> Result<ExtensionResponse> {
        let cart = Cart::from(&invocation)?;
        let subtotal = invocation.input::<Cents>()?;
        // 10 percent off, capped at $25.
        let discount = Percentage::from_whole(10)?.of(subtotal)?.min(Cents::from_dollars(25)?);
        let total = subtotal.checked_sub(discount)?;
        let patch = cart.patch().discount_cents(discount).total_cents(total);
        Ok(ExtensionResponse::new(Applied { discount_cents: discount, total_cents: total }).patch(patch))
    }
}
