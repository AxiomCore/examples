use crate::axiom_bindings::ui::Forecast;
use axiom_extension_sdk::prelude::*;

#[derive(Default)]
struct DeliveryRisk;

#[derive(AxiomType)]
struct RiskInput {
    id: String,
    workspace_name: String,
    active_projects: u64,
    total_tasks: u64,
    completed_tasks: u64,
    blocked_tasks: u64,
    team_members: u64,
    week_label: String,
}

#[derive(AxiomType)]
struct RiskAssessment {
    risk_score: u64,
    risk_label: String,
    risk_summary: String,
}

#[extension]
impl DeliveryRisk {
    #[export]
    fn assess_delivery_risk(&mut self, invocation: TypedInvocation) -> Result<ExtensionResponse> {
        let forecast = Forecast::from(&invocation)?;
        // Acore's non-negative Int values cross the language-neutral ABI as
        // unsigned integers. Keeping the authored type aligned avoids a
        // signed/unsigned decode trap while retaining saturating arithmetic.
        let input = invocation.input::<RiskInput>()?;
        let blocked = input.blocked_tasks;
        let total = input.total_tasks;
        let completed = input.completed_tasks;
        let open = total.saturating_sub(completed);
        let score = (blocked * 18 + open * 2).clamp(0, 96);
        let label = if score >= 70 {
            "Critical"
        } else if score >= 45 {
            "Watch"
        } else {
            "Healthy"
        };
        let summary = format!("{blocked} blocked · {open} open · deterministic score {score}/100");

        Ok(ExtensionResponse::new(RiskAssessment {
            risk_score: score,
            risk_label: label.into(),
            risk_summary: summary.clone(),
        })
        .patch(
            forecast
                .patch()
                .risk_score(score)
                .risk_label(label)
                .risk_summary(summary)
                .engine_label("Rust · verified capability-scoped WASM"),
        ))
    }
}
