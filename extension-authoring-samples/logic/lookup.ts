// Lookup extension used by the extension documentation: one yield with two
// host calls, read back with typed tickets.
import {
  Cents,
  defineExtension,
  operation,
  type Effects,
  type ExtensionContext,
  type ResumeContext,
} from "@axiomcore/extension-sdk";

const priceOf = operation<string, number>("contract_runtime", "query_catalog_683b531f41ec88a2");
const stockOf = operation<string, number>("contract_runtime", "query_catalog_08c4242b5f585628");

// The resume runs in a fresh engine, so it rebuilds the same plan (same calls,
// same inputs, same order) and reads the tickets of the rebuilt plan.
// The resume receives no input, so the plan uses only constants.
const FEATURED = "featured";
const plan = (fx: Effects) => ({
  price: fx.push(priceOf.call(FEATURED)),
  stock: fx.push(stockOf.call(FEATURED)),
});

export default defineExtension({
  exports: {
    lookup(context: ExtensionContext) {
      const fx = context.plan();
      plan(fx);
      return context.effects(fx);
    },
  },
  resume(resume: ResumeContext) {
    const tickets = plan(resume.plan());
    const price = Cents.decode(resume.get(tickets.price));
    const stock = resume.get(tickets.stock);
    return resume.complete({ in_stock: stock > 0, price_label: price.asCurrency() });
  },
});
