import { defineExtension } from "@axiomcore/extension-sdk";
import { selectors } from "@axiomcore/extension-bindings";

export default defineExtension({
  exports: {
    assess_delivery_risk(context) {
      const forecast = context.snapshot("ui:forecast");
      const input = context.input as { blocked_tasks: number; total_tasks: number; completed_tasks: number };
      const blocked = Number(input.blocked_tasks);
      const total = Number(input.total_tasks);
      const completed = Number(input.completed_tasks);
      const open = Math.max(0, total - completed);
      const score = Math.min(96, Math.max(0, blocked * 18 + open * 2));
      const label = score >= 70 ? "Critical" : score >= 45 ? "Watch" : "Healthy";
      const summary = `${blocked} blocked · ${open} open · deterministic score ${score}/100`;
      return context.complete(
        { risk_score: score, risk_label: label, risk_summary: summary },
        {
          patches: [context.patch("ui:forecast")
            .set(selectors.ui_forecast_risk_score, score)
            .set(selectors.ui_forecast_risk_label, label)
            .set(selectors.ui_forecast_risk_summary, summary)
            .set(selectors.ui_forecast_engine_label, "TypeScript · verified Javy WASM")
            .build()],
        },
      );
    },
  },
});
