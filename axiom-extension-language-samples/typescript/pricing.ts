import { defineExtension } from "@axiomcore/extension-sdk";
import { selectors } from "@axiomcore/extension-bindings";

export default defineExtension({
  exports: {
    calculate_discount(context) {
      const subtotal = Number(
        context.input ?? context.snapshot("ui:cart").get(selectors.ui_cart_subtotal_cents),
      );
      if (!Number.isSafeInteger(subtotal) || subtotal < 0) {
        throw new Error("subtotal must be a non-negative integer");
      }
      const discount = Math.min(Math.floor(subtotal / 10), 2_500);
      const total = subtotal - discount;
      return context.complete(
        { discount_cents: discount, total_cents: total },
        {
          patches: [
            context
              .patch("ui:cart")
              .set(selectors.ui_cart_discount_cents, discount)
              .set(selectors.ui_cart_total_cents, total)
              .build(),
          ],
        },
      );
    },
  },
});
