//! Runs the extension documentation samples (`examples/extension-authoring-samples`).
//!
//! `axiom extensions run` uses a reference host that answers no contract
//! queries, so it cannot show the async `quote` export. This harness loads the
//! *released, signed* extension exactly as the CLI does
//! (`load_verified_extension_target` on `AxiomExtensions.toml`), seeds a
//! deterministic host with the scenario's contract replies and UI state, and
//! invokes each scenario through `TargetExtensionHost` (kernel, broker,
//! budgets, rounds, audit).
//!
//! Usage: `harness <scenarios.json> <project-directory> [<tape-directory>]`.
//! `axiom extensions source-release` writes a workflow file per alias; the
//! harness reads `AxiomExtensions.<alias>.toml` when it exists, otherwise
//! `AxiomExtensions.toml`.
//! `HARNESS_DEADLINE_MS` (default 1000, the kernel default) is the host
//! policy's deadline ceiling; the package's signed `deadlineMs` still applies.
//! With a tape directory, every invocation is also recorded as a dev replay
//! tape. Prints one canonical (JCS) JSON document.
use anyhow::{bail, Context, Result};
use axiom_extension_abi::{Field, Invocation, Snapshot, Value};
use axiom_extension_broker::{DeterministicHost, HostReply, InvocationContext, SensitivePolicy};
use axiom_extension_host::{DevReplayTapeOptions, HostProfile, LifecycleEvent, TargetExtensionHost};
use axiom_extension_kernel::{AuthorizedModule, KernelPolicy, SandboxKernel};
use axiom_lib::{
    extension_authority::{decode_authority_lock, EffectiveTargetAuthority},
    extension_workflow::load_verified_extension_target,
    package::{decode_axiom_package, DecodedAxiomPackage, ExtensionPackagePayload, PackageContents, PackageTarget},
};
use serde::Deserialize;
use serde_json::json;
use sha2::{Digest, Sha256};
use std::{path::Path, sync::Arc};

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Suite {
    aliases: Vec<String>,
    scenarios: Vec<Scenario>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Scenario {
    name: String,
    export: String,
    input: serde_json::Value,
    #[serde(default)]
    contracts: Vec<ContractReply>,
    ui: Option<UiState>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct ContractReply {
    service: String,
    method: String,
    reply: serde_json::Value,
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
        serde_json::Value::Array(values) => Value::List(values.into_iter().map(json_to_value).collect::<Result<_>>()?),
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
    language: String,
    sdk: String,
    module_sha256: String,
    abi: String,
    authorized: AuthorizedModule,
    effective: EffectiveTargetAuthority,
    max_effects: u32,
    max_stream_batch: u32,
}

fn policy() -> KernelPolicy {
    let ceiling = std::env::var("HARNESS_DEADLINE_MS").ok().and_then(|value| value.parse().ok()).unwrap_or(1_000);
    KernelPolicy { deadline_ms: ceiling, ..KernelPolicy::default() }
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
        &policy(),
        false,
    )?;
    Ok(Loaded {
        effective: EffectiveTargetAuthority {
            permissions: target.effective.permissions.clone(),
            budgets: target.effective.budgets.clone(),
        },
        language: executable.sdk.language.clone(),
        sdk: format!("{}@{}", executable.sdk.language, executable.sdk.version),
        module_sha256: sha256(&target.module_bytes),
        abi: executable.abi.version.clone(),
        max_effects: executable.limits.max_effects,
        max_stream_batch: executable.limits.max_stream_batch,
        authorized,
    })
}

async fn run(loaded: &Loaded, alias: &str, kernel: &SandboxKernel, scenario: &Scenario, tapes: Option<&Path>) -> Result<serde_json::Value> {
    let services = Arc::new(DeterministicHost::default());
    for contract in &scenario.contracts {
        services.set_contract(&contract.service, &contract.method, HostReply::Value(json_to_value(contract.reply.clone())?));
    }
    if let Some(ui) = &scenario.ui {
        services.state_store().define_ui(&ui.scope, json_to_value(serde_json::Value::Object(ui.value.clone()))?, Vec::new())?;
    }
    let authorized = loaded.authorized.clone();
    let host_services = Arc::clone(&services);
    let (effects, batch) = (loaded.max_effects, loaded.max_stream_batch);
    let host = match loaded.language.as_str() {
        "typescript" => TargetExtensionHost::load_typescript(HostProfile::backend(), authorized, &loaded.effective, host_services, 1, effects, batch)?,
        "python" => TargetExtensionHost::load_python(HostProfile::backend(), authorized, &loaded.effective, host_services, 1, effects, batch)?,
        _ => TargetExtensionHost::load(HostProfile::backend(), kernel, authorized, &loaded.effective, host_services, 1, effects, batch)?,
    };
    if let Some(directory) = tapes {
        host.enable_dev_replay_tape(DevReplayTapeOptions {
            directory: directory.to_path_buf(),
            sensitive: SensitivePolicy::Refuse,
            sdk: Some(loaded.sdk.clone()),
            alias: Some(alias.to_string()),
            allow_release_build_recording_of_real_user_data: false,
        })?;
    }
    let started = std::time::Instant::now();
    let result = host.invoke(invocation(scenario)?, InvocationContext::default()).await;
    let elapsed_ms = started.elapsed().as_millis() as u64;
    let teardown = host.lifecycle(LifecycleEvent::AppShutdown);
    let outcome = match &result {
        Ok(result) => json!({"status": "completed", "output": result.output, "patches": result.patches}),
        Err(error) => json!({"status": "rejected", "error": error.to_string()}),
    };
    // The language-independent view of what the broker did: one entry per
    // audited effect, in order (round, operation, decision).
    let effects: Vec<serde_json::Value> = host
        .broker()
        .audit_records()
        .iter()
        .map(|record| {
            let record = serde_json::to_value(record).unwrap_or_default();
            json!({
                "round": record.get("round").cloned().unwrap_or(json!(1)),
                "namespace": record.get("namespace").cloned().unwrap_or_default(),
                "operation": record.get("operation").cloned().unwrap_or_default(),
                "decision": record.get("decision").cloned().unwrap_or_default(),
                "site": record.get("site").cloned().unwrap_or(serde_json::Value::Null),
            })
        })
        .collect();
    let state_after = scenario
        .ui
        .as_ref()
        .and_then(|ui| services.state_store().ui_snapshot(&ui.scope))
        .map(|(revision, value)| json!({"revision": revision, "value": value}));
    Ok(json!({
        "outcome": outcome,
        "effects": effects,
        "uiStateAfter": state_after,
        "teardown": teardown.map(|_| "ok".to_string()).unwrap_or_else(|error| error.to_string()),
        "elapsedMs": elapsed_ms,
    }))
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    let usage = "usage: harness <scenarios.json> <project-directory> [<tape-directory>]";
    let path = std::env::args().nth(1).context(usage)?;
    let workflow = std::env::args().nth(2).context(usage)?;
    let tapes = std::env::args().nth(3);
    let path = Path::new(&path);
    let suite: Suite = serde_json::from_slice(&std::fs::read(path)?).with_context(|| format!("parse {}", path.display()))?;
    let kernel = SandboxKernel::new(policy())?;
    let mut extensions = Vec::new();
    for alias in &suite.aliases {
        let project = Path::new(&workflow);
        let per_alias = project.join(format!("AxiomExtensions.{alias}.toml"));
        let manifest = if per_alias.is_file() { per_alias } else { project.join("AxiomExtensions.toml") };
        let loaded = load(&manifest, alias)?;
        let mut results = Vec::new();
        for scenario in &suite.scenarios {
            let tape_dir = tapes.as_ref().map(|root| Path::new(root).join(alias));
            let result = run(&loaded, alias, &kernel, scenario, tape_dir.as_deref()).await?;
            results.push(json!({"name": scenario.name, "result": result}));
        }
        extensions.push(json!({
            "alias": alias,
            "language": loaded.language,
            "sdk": loaded.sdk,
            "abi": loaded.abi,
            "moduleSha256": loaded.module_sha256,
            "scenarios": results,
        }));
    }
    let report = json!({"format": "axiom-examples-extension-docs/v1", "extensions": extensions});
    println!("{}", String::from_utf8(serde_jcs::to_vec(&report)?)?);
    Ok(())
}
