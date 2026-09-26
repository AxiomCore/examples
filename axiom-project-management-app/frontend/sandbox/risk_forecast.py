from axiom_extension_sdk import extension
from axiom_bindings import selectors


@extension.export
def assess_delivery_risk(context):
    forecast = context.snapshot("ui:forecast")
    blocked = int(context.input["blocked_tasks"])
    total = int(context.input["total_tasks"])
    completed = int(context.input["completed_tasks"])
    open_tasks = max(0, total - completed)
    score = min(96, max(0, blocked * 18 + open_tasks * 2))
    label = "Healthy"
    if score >= 70:
        label = "Critical"
    elif score >= 45:
        label = "Watch"
    summary = str(blocked) + " blocked · " + str(open_tasks) + " open · deterministic score " + str(score) + "/100"
    patch = (
        context.patch("ui:forecast")
        .set(selectors.ui_forecast_risk_score, score)
        .set(selectors.ui_forecast_risk_label, label)
        .set(selectors.ui_forecast_risk_summary, summary)
        .set(selectors.ui_forecast_engine_label, "Python · verified AOT WASM")
        .build()
    )
    return context.complete(
        {"risk_score": score, "risk_label": label, "risk_summary": summary},
        patches=[patch],
    )
