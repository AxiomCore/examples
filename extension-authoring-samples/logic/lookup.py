"""Lookup extension used by the extension documentation: one yield with two
host calls, read back with typed tickets."""
from typing import TYPE_CHECKING

from axiom_extension_sdk import Cents, Ticket, extension, typed_effect

if TYPE_CHECKING:
    from axiom_extension_sdk import Context, Effects, ResumeContext


# The resume receives no input, so the plan uses only constants.
FEATURED = "featured"


def plan(fx: "Effects") -> "tuple[Ticket[int], Ticket[int]]":
    price = fx.push(typed_effect("contract_runtime", "query_catalog_683b531f41ec88a2", {"String": FEATURED}, int))
    stock = fx.push(typed_effect("contract_runtime", "query_catalog_08c4242b5f585628", {"String": FEATURED}, int))
    return price, stock


@extension.export
def lookup(ctx: "Context"):
    fx = ctx.plan()
    plan(fx)
    return ctx.effects(fx)


@extension.resume
def resume(ctx: "ResumeContext"):
    # The resume runs in a fresh engine: rebuild the same plan, then read it.
    price, stock = plan(ctx.plan())
    return ctx.complete({"in_stock": ctx.get(stock) > 0, "price_label": Cents.decode(ctx.get(price)).as_currency()})
