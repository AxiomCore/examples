"""Pricing extension used by the extension documentation. `quote` is an async
export that needs three effect rounds; `apply_discount` is a sync export that
proposes a UI patch."""
from typing import TYPE_CHECKING

from axiom_extension_sdk import Cents, Percentage, extension, gather, typed_effect
from axiom_bindings import selectors

if TYPE_CHECKING:
    from axiom_extension_sdk import AsyncContext, Context


# Import names of the granted catalog queries, as listed by
# `axiom extensions interface pricingpy`.
def price_of(sku: str):
    return typed_effect("contract_runtime", "query_catalog_683b531f41ec88a2", {"String": sku}, int)


def stock_of(sku: str):
    return typed_effect("contract_runtime", "query_catalog_08c4242b5f585628", {"String": sku}, int)


def discount_of(sku: str):
    return typed_effect("contract_runtime", "query_catalog_221617318bcf5128", {"String": sku}, int)


def shipping_of(sku: str):
    return typed_effect("contract_runtime", "query_catalog_740062676a3134f3", {"String": sku}, int)


@extension.export
async def quote(cx: "AsyncContext", sku: str):
    # Round 1: one host call.
    price = Cents.decode(await cx.call(price_of(sku)))
    # Round 2: two independent calls, sent together as one group.
    stock, discount = await gather(cx.call(stock_of(sku)), cx.call(discount_of(sku)))
    if stock == 0:
        return cx.complete({"available": False, "label": "Out of stock", "total_cents": Cents.ZERO.encode()})
    # Round 3: only reached when the item is in stock.
    shipping = Cents.decode(await cx.call(shipping_of(sku)))
    discounted = price.checked_sub(Percentage.decode(discount).of(price))
    total = Cents(discounted.value + shipping.value)
    return cx.complete({"available": True, "label": total.as_currency(), "total_cents": total.encode()})


@extension.export
def apply_discount(context: "Context"):
    subtotal = Cents.decode(context.input)
    # 10 percent off, capped at $25.
    discount = Percentage.from_whole(10).of(subtotal).min(Cents.from_dollars(25))
    total = subtotal.checked_sub(discount)
    patch = (
        context.patch("ui:cart")
        .set(selectors.ui_cart_discount_cents, discount.encode())
        .set(selectors.ui_cart_total_cents, total.encode())
        .build()
    )
    return context.complete(
        {"discount_cents": discount.encode(), "total_cents": total.encode()},
        patches=[patch],
    )
