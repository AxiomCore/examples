//! X7 migration golden harness for the example apps.
//!
//! `axiom extensions run` (the CLI reference host) invokes an export without
//! UI snapshots, so it cannot show the patches a UI extension proposes. This
//! harness loads the *released, signed* extension exactly as the CLI does
//! (`load_verified_extension_target` on `AxiomExtensions.toml`), then runs
//! each scenario twice:
//!
//! * `kernel`: the raw guest exchange on the real kernel (native Wasmi kernel
//!   for Rust, the managed Javy kernel for TypeScript and Python), with the
//!   scenario's UI snapshot. It records the step, the output, the proposed
//!   patches and the postcard wire bytes of the completion (and of any
//!   yielded plan).
//! * `host`: the same invocation through `TargetExtensionHost` (broker,
//!   budgets, audit) with the UI state seeded in a `DeterministicHost`. It
//!   records the result and the host, broker and state audit records.
//!
//! Usage: `axiom-examples-x7-golden-harness <scenarios.json> <AxiomExtensions.toml>`.
//! Prints one canonical (JCS) JSON document.
use anyhow::{bail, Context, Result};
use axiom_extension_abi::{self as abi, Field, Invocation, Snapshot, Value};
use axiom_extension_broker::{DeterministicHost, InvocationContext};
use axiom_extension_host::{HostProfile, LifecycleEvent, TargetExtensionHost};
use axiom_extension_kernel::{
    AuthorizedModule, CancellationToken, ExtensionSandbox, InvocationStep, KernelPolicy,
    SandboxKernel,
};
use axiom_extension_typescript_kernel::{
    managed_fuel_ceiling, CompiledTypeScriptProgram, TypeScriptKernelLimits,
    TypeScriptSandboxInstance,
};
use axiom_lib::{
    extension_authority::{decode_authority_lock, EffectiveTargetAuthority},
    extension_workflow::{load_verified_extension_target, LoadedExtensionTarget},
    package::{
        decode_axiom_package, DecodedAxiomPackage, ExtensionPackagePayload, PackageContents,
        PackageTarget,
    },
};
use serde::Deserialize;
use serde_json::json;
use sha2::{Digest, Sha256};
use std::{path::Path, sync::Arc, time::Duration};

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Suite {
    alias: String,
    scenarios: Vec<Scenario>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Scenario {
    name: String,
    export: String,
    input: serde_json::Value,
    /// UI state the action host would hold. The guest receives a snapshot of
    /// `read` fields only (the host redacts to effective read paths).
    ui: Option<UiState>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct UiState {
    scope: String,
    revision: u64,
    read: Vec<String>,
    value: serde_json::Map<String, serde_json::Value>,
}

/// A fixed deadline far in the future keeps the invocation bytes stable.
const DEADLINE_UNIX_MS: u64 = 4_102_444_800_000;
const WIRE: abi::CodecLimits = abi::CodecLimits { max_bytes: 1 << 20 };

fn wire<T: serde::Serialize>(value: &T) -> Result<Vec<u8>> {
    abi::encode(value, WIRE).map_err(|error| anyhow::anyhow!("ABI encode: {error:?}"))
}

fn sha256(bytes: &[u8]) -> String {
    Sha256::digest(bytes).iter().map(|b| format!("{b:02x}")).collect()
}

fn json_to_value(value: serde_json::Value) -> Result<Value> {
    Ok(match value {
        serde_json::Value::Null => Value::Null,
        serde_json::Value::Bool(value) => Value::Bool(value),
        serde_json::Value::Number(value) => match (value.as_u64(), value.as_i64()) {
            (Some(value), _) => Value::Unsigned(value),
            (None, Some(value)) => Value::Signed(value),
            _ => bail!("ABI v1 has no floating-point values"),
        },
        serde_json::Value::String(value) => Value::String(value),
        serde_json::Value::Array(values) => {
            Value::List(values.into_iter().map(json_to_value).collect::<Result<_>>()?)
        }
        serde_json::Value::Object(values) => Value::Record(
            values
                .into_iter()
                .map(|(name, value)| Ok(Field { name, value: json_to_value(value)? }))
                .collect::<Result<_>>()?,
        ),
    })
}

fn snapshot(ui: &UiState) -> Result<Snapshot> {
    let mut fields = Vec::new();
    for name in &ui.read {
        let value = ui.value.get(name).with_context(|| format!("ui.value has no `{name}`"))?;
        fields.push(Field { name: name.clone(), value: json_to_value(value.clone())? });
    }
    fields.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(Snapshot { resource: format!("ui:{}", ui.scope), revision: ui.revision, value: Value::Record(fields) })
}

fn invocation(scenario: &Scenario) -> Result<Invocation> {
    Ok(Invocation {
        export: scenario.export.clone(),
        input: json_to_value(scenario.input.clone())?,
        snapshots: scenario.ui.as_ref().map(snapshot).transpose()?.into_iter().collect(),
        deadline_unix_ms: DEADLINE_UNIX_MS,
    })
}

struct Loaded {
    target: LoadedExtensionTarget,
    language: String,
    authorized: AuthorizedModule,
    effective: EffectiveTargetAuthority,
    max_effects: u32,
    max_stream_batch: u32,
}

fn load(workflow: &Path, alias: &str) -> Result<Loaded> {
    let target = load_verified_extension_target(workflow, alias, PackageTarget::Server)?;
    let DecodedAxiomPackage::Package(package) = decode_axiom_package(&target.package_bytes)? else {
        bail!("legacy extension packages cannot execute");
    };
    let PackageContents::Extension(ExtensionPackagePayload::V2(executable)) = &package.contents else {
        bail!("selected package is not axiom-extension/v2");
    };
    let authority_lock = decode_authority_lock(&target.authority_lock_bytes)?;
    let authorized = AuthorizedModule::verify_brokered(
        &target.application,
        &package.package,
        executable,
        &package.targets,
        &authority_lock,
        PackageTarget::Server,
        &target.module_bytes,
        &KernelPolicy::default(),
        false,
    )?;
    Ok(Loaded {
        effective: EffectiveTargetAuthority {
            permissions: target.effective.permissions.clone(),
            budgets: target.effective.budgets.clone(),
        },
        language: executable.sdk.language.clone(),
        max_effects: executable.limits.max_effects,
        max_stream_batch: executable.limits.max_stream_batch,
        authorized,
        target,
    })
}

fn sandbox(loaded: &Loaded, kernel: &SandboxKernel) -> Result<Box<dyn ExtensionSandbox>> {
    let authorized = loaded.authorized.clone();
    if loaded.language == "rust" {
        return Ok(Box::new(kernel.load(authorized)?));
    }
    let limits = authorized.limits();
    let program = CompiledTypeScriptProgram::compile(
        authorized.module_bytes(),
        TypeScriptKernelLimits {
            fuel: managed_fuel_ceiling(limits.fuel_per_invocation),
            max_memory_pages: limits.max_memory_pages,
            max_input_bytes: limits.max_message_bytes as usize,
            max_output_bytes: limits.max_message_bytes as usize,
        },
    )?;
    // Debug-build interpreters are slow; the deadline is not under test.
    let adapter = TypeScriptSandboxInstance::with_deadline(Arc::new(program), Duration::from_secs(300));
    Ok(authorized.check_adapter(Box::new(adapter)))
}

fn kernel_exchange(sandbox: &dyn ExtensionSandbox, invocation: Invocation) -> Result<serde_json::Value> {
    let invocation_wire = wire(&invocation)?;
    let step = sandbox.begin_invocation(invocation, CancellationToken::default())?;
    Ok(match step {
        InvocationStep::Completed(result) => {
            let wire = wire(&result)?;
            json!({
                "step": "completed",
                "invocationWireSha256": sha256(&invocation_wire),
                "output": result.output,
                "patches": result.patches,
                "transactions": result.transactions,
                "events": result.emitted_events,
                "resultWireSha256": sha256(&wire),
                "resultWireBytes": wire.len(),
            })
        }
        InvocationStep::Yielded { request_id, plan } => {
            let wire = wire(&plan)?;
            sandbox.cancel_yielded(request_id)?;
            json!({"step": "yielded", "invocationWireSha256": sha256(&invocation_wire), "plan": plan, "planWireSha256": sha256(&wire)})
        }
        InvocationStep::GuestFailed(error) => {
            json!({"step": "guest-failed", "invocationWireSha256": sha256(&invocation_wire), "error": error})
        }
        other => json!({"step": format!("{other:?}")}),
    })
}

async fn host_exchange(loaded: &Loaded, kernel: &SandboxKernel, scenario: &Scenario) -> Result<serde_json::Value> {
    let services = Arc::new(DeterministicHost::default());
    if let Some(ui) = &scenario.ui {
        services.state_store().define_ui(
            &ui.scope,
            json_to_value(serde_json::Value::Object(ui.value.clone()))?,
            Vec::new(),
        )?;
    }
    let authorized = loaded.authorized.clone();
    let services_for_host = Arc::clone(&services);
    let (effects, batch) = (loaded.max_effects, loaded.max_stream_batch);
    let host = match loaded.language.as_str() {
        "typescript" => TargetExtensionHost::load_typescript(HostProfile::backend(), authorized, &loaded.effective, services_for_host, 1, effects, batch)?,
        "python" => TargetExtensionHost::load_python(HostProfile::backend(), authorized, &loaded.effective, services_for_host, 1, effects, batch)?,
        _ => TargetExtensionHost::load(HostProfile::backend(), kernel, authorized, &loaded.effective, services_for_host, 1, effects, batch)?,
    };
    let result = host.invoke(invocation(scenario)?, InvocationContext::default()).await;
    let teardown = host.lifecycle(LifecycleEvent::AppShutdown);
    let outcome = match &result {
        Ok(result) => json!({"status": "completed", "output": result.output, "patches": result.patches, "transactions": result.transactions, "events": result.emitted_events}),
        Err(error) => json!({"status": "rejected", "error": error.to_string()}),
    };
    let state_after = scenario
        .ui
        .as_ref()
        .and_then(|ui| services.state_store().ui_snapshot(&ui.scope))
        .map(|(revision, value)| json!({"revision": revision, "value": value}));
    Ok(json!({
        "outcome": outcome,
        "teardown": teardown.map(|_| "ok".to_string()).unwrap_or_else(|error| error.to_string()),
        "provenance": host.provenance(),
        "hostAudit": host.audit_records(),
        "brokerAudit": host.broker().audit_records(),
        "brokerActiveHandles": host.broker().active_handle_count(),
        "stateAudit": services.state_store().audit_records(),
        "uiStateAfter": state_after,
    }))
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    let usage = "usage: harness <scenarios.json> <AxiomExtensions.toml>";
    let path = std::env::args().nth(1).context(usage)?;
    let workflow = std::env::args().nth(2).context(usage)?;
    let path = Path::new(&path);
    let suite: Suite = serde_json::from_slice(&std::fs::read(path)?).with_context(|| format!("parse {}", path.display()))?;
    let loaded = load(Path::new(&workflow), &suite.alias)?;
    let kernel = SandboxKernel::new(KernelPolicy::default())?;
    let mut results = Vec::new();
    for scenario in &suite.scenarios {
        let guest = sandbox(&loaded, &kernel)?;
        let kernel_result = kernel_exchange(guest.as_ref(), invocation(scenario)?)?;
        guest.drain_and_shutdown()?;
        let host_result = host_exchange(&loaded, &kernel, scenario).await?;
        results.push(json!({"name": scenario.name, "kernel": kernel_result, "host": host_result}));
    }
    let report = json!({
        "format": "axiom-examples-x7-golden/v1",
        "alias": suite.alias,
        "language": loaded.language,
        "application": loaded.target.application,
        "moduleSha256": sha256(&loaded.target.module_bytes),
        "interfaceSha256": loaded.target.report.provenance.interface_sha256,
        "scenarios": results,
    });
    println!("{}", String::from_utf8(serde_jcs::to_vec(&report)?)?);
    Ok(())
}
