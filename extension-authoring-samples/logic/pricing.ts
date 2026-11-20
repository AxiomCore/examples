// Pricing extension used by the extension documentation. `quote` is an async
// export that needs three effect rounds; `apply_discount` is a sync export
// that proposes a UI patch.
import {
  Cents,
  Percentage,
  defineExtension,
  extension,
  operation,
  type AsyncContext,
  type ExtensionContext,
} from "@axiomcore/extension-sdk";
import { selectors } from "@axiomcore/extension-bindings";

// Import names of the granted catalog queries, as listed by
// `axiom extensions interface pricingts`.
const priceOf = operation<string, number>("contract_runtime", "query_catalog_683b531f41ec88a2");
const stockOf = operation<string, number>("contract_runtime", "query_catalog_08c4242b5f585628");
const discountOf = operation<string, number>("contract_runtime", "query_catalog_221617318bcf5128");
const shippingOf = operation<string, number>("contract_runtime", "query_catalog_740062676a3134f3");

export default defineExtension({
  exports: {
    quote: extension.export(async (cx: AsyncContext, input: unknown) => {
      const sku = String(input);
      // Round 1: one host call.
      const price = Cents.decode(await cx.call(priceOf.call(sku)));
      // Round 2: two independent calls, sent together as one group.
      const [stock, discount] = await Promise.all([
        cx.call(stockOf.call(sku)),
        cx.call(discountOf.call(sku)),
      ]);
      if (stock === 0) {
        return cx.complete({ available: false, label: "Out of stock", total_cents: Cents.ZERO.encode() });
      }
      // Round 3: only reached when the item is in stock.
      const shipping = Cents.decode(await cx.call(shippingOf.call(sku)));
      const discounted = price.checkedSub(Percentage.decode(discount).of(price));
      const total = Cents.new(discounted.value + shipping.value);
      return cx.complete({ available: true, label: total.asCurrency(), total_cents: total.encode() });
    }),

    apply_discount(context: ExtensionContext) {
      const subtotal = Cents.decode(context.input);
      // 10 percent off, capped at $25.
      const discount = Percentage.fromWhole(10).of(subtotal).min(Cents.fromDollars(25));
      const total = subtotal.checkedSub(discount);
      const patch = context
        .patch("ui:cart")
        .set(selectors.ui_cart_discount_cents, discount.encode())
        .set(selectors.ui_cart_total_cents, total.encode())
        .build();
      return context.complete(
        { discount_cents: discount.encode(), total_cents: total.encode() },
        { patches: [patch] },
      );
    },
  },
});
