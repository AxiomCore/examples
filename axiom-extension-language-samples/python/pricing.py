from axiom_extension_sdk import Context, extension
from axiom_bindings import selectors


@extension.export
def calculate_discount(context: Context):
    subtotal: int | None = context.input
    if subtotal is None:
        subtotal = context.snapshot("ui:cart").get(selectors.ui_cart_subtotal_cents)
    if subtotal is None:
        raise ValueError("subtotal is unavailable")
    if subtotal < 0:
        raise ValueError("subtotal must be a non-negative integer")

    discount = min(subtotal // 10, 2_500)
    total = subtotal - discount
    patch = (
        context.patch("ui:cart")
        .set(selectors.ui_cart_discount_cents, discount)
        .set(selectors.ui_cart_total_cents, total)
        .build()
    )
    return context.complete(
        {"discount_cents": discount, "total_cents": total},
        patches=[patch],
    )
