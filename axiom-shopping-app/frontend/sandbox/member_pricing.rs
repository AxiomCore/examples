use crate::axiom_bindings::ui::Cart;
use axiom_extension_sdk::prelude::*;

#[derive(Default)]
struct MemberPricing;

#[derive(AxiomType)]
struct PricingResult {
    discount_cents: Cents,
    discount_label: String,
    total_label: String,
}

#[extension]
impl MemberPricing {
    #[export]
    fn apply_member_price(&mut self, invocation: TypedInvocation) -> Result<ExtensionResponse> {
        let cart = Cart::from(&invocation).ok();
        let subtotal = invocation.input::<Cents>().or_else(|input_error| {
            cart.as_ref()
                .map(|cart| cart.subtotal_cents::<Cents>())
                .transpose()?
                .ok_or(input_error)
        })?;

        // Members receive 15%, capped at $40. The host still validates and
        // atomically commits the generated, revision-checked cart patch.
        let discount = Percentage::from_whole(15)?
            .of(subtotal)?
            .min(Cents::from_dollars(40)?);
        let total = subtotal.checked_sub(discount)?;
        let discount_label = discount.as_saving();
        let total_label = total.as_currency();

        let response = ExtensionResponse::new(PricingResult {
            discount_cents: discount,
            discount_label: discount_label.clone(),
            total_label: total_label.clone(),
        });
        Ok(match cart {
            Some(cart) => response.patch(
                cart.patch()
                    .discount_cents(discount)
                    .discount_label(discount_label)
                    .total_label(total_label)
                    .pricing_status("Member price applied by verified Rust WASM · you saved 15%."),
            ),
            None => response,
        })
    }
}
