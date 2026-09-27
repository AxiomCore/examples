# AxiomCore examples

Public, runnable examples for the [AxiomCore](https://github.com/AxiomCore/AxiomCore) CLI, Acore language, client SDKs, and UI runtime. These use synthetic data and local services. They are learning and validation fixtures, not production templates or a promise that every target is stable.

Start with a single directory; each example owns its dependencies and commands. The status below describes the example's intended use, not the overall maturity of its underlying product capability. Check the [public support matrix](https://docs.axiomcore.dev/introduction/support-matrix) before choosing a production integration.

| Example | Status | What it demonstrates |
| --- | --- | --- |
| [`domain-commerce`](domain-commerce) | Start here | Domain entities, invariants, projections, and semantic change review |
| [`domain-support`](domain-support) | Start here | Small audience-specific domain projection |
| [`domain-inference-fastapi`](domain-inference-fastapi) | Guided | FastAPI/Pydantic extraction and domain promotion |
| [`security-mode-v1`](security-mode-v1) | Guided | Passing audit fixture and intentionally rejected strict fixture |
| [`simple-backend`](simple-backend) | Integration | FastAPI/Go service with web, React, and Flutter consumers |
| [`offline-first-feed`](offline-first-feed) | Integration | Cached feed and offline/online consumer behavior |
| [`realtime-chat`](realtime-chat) | Integration | Go streaming service with multiple client targets |
| [`axiom-shopping-app`](axiom-shopping-app) | Demo | Contract-driven shopping UI, state, and Rust extension |
| [`axiom-project-management-app`](axiom-project-management-app) | Demo | Flowspace project management UI and capability-scoped extensions |
| [`extension-sandbox`](extension-sandbox) | Advanced | Authored Rust extension with bounded authority |
| [`axiom-extension-language-samples`](axiom-extension-language-samples) | Preview fixture | TypeScript/Python extension source and dependency-resolution cases; requires a development CLI |
| [`ui-feature-gallery`](ui-feature-gallery) | Source gallery | Styles, layout, text, elements, scrolling, input, and component examples |
| [`ui-interaction-demos`](ui-interaction-demos) | Source demos | State, navigation, assets, and contract-backed tasks |
| [`package-dependencies`](package-dependencies) | Guided fixture | Pinned theme and component-library packages across platforms |
| [`native-ui-first-render`](native-ui-first-render) | Source demo | Minimal native-rendered Acore page with local state |
| [`axiom-ui-task-app`](axiom-ui-task-app) | Compiler fixture | Virtual Acore UI compile/check without a native host |
| [`demo-app`](demo-app) | Legacy fixture | Small contract/build experiment; not the recommended starting point |
| [`rpc`](rpc), [`stream`](stream), [`observability-and-auth`](observability-and-auth) | Maintainer fixtures | Lower-level Flutter/runtime behavior, RPC, streams, and auth |

## First run

Install the current [Axiom CLI](https://github.com/AxiomCore/AxiomCore#start-locally), then validate a self-contained example:

```sh
cd domain-commerce
axiom domain validate commerce-v1.acore
axiom diff commerce-v1.acore commerce-v2.acore --format semantic
```

The second contract intentionally removes a projected field; treat that as a consumer-breaking change even if the current semantic output does not classify it automatically. `axiom build` requires a configured local CLI/runtime environment and is not part of this minimal smoke test. For FastAPI extraction, use [`domain-inference-fastapi`](domain-inference-fastapi/README.md) and install its Python dependencies first. For a full application, follow the README in its directory and run the backend and frontend in separate terminals.

## Release verification

The [Acore smoke workflow](.github/workflows/smoke.yml) and
[extension SDK workflow](.github/workflows/extension-sdk.yml) run after each release
train (including subset releases), on pull requests, and on pushes to `main`.
It selects the newest stable CLI release with a macOS ARM64 archive, verifies
the published SHA-256 digest, and does the same for the Go and FastAPI
extractors. It never selects a UI-host or runtime release as the CLI.
The web UI host is fetched with the workflow token and its asset digests;
the CLI then verifies its signed manifest before use.

The Acore job builds and HTTP-probes every backend mock, compiles every Acore
web entry point, HTTP-probes every Acore web UI, validates both domain
examples, and checks the strict-security fixture fails for the expected
reason. The npm and Flutter demo clients remain available for manual or
target-specific checks, but are not part of this release-triggered test.
Native-only gallery variants are not treated as web examples. The extension
SDK job installs the three Rust, one TypeScript, and one Python SDK examples
from crates.io, npm, and PyPI using committed locks. It checks generated editor
bindings and language compilation. This is not a runtime WASM test.

Three Acore web examples (`axiom-project-management-app`,
`axiom-shopping-app`, and `extension-sandbox`) use authored Rust extensions.
Since CLI v0.147.2, the released-CLI Acore smoke job compiles and exercises
these three web hosts instead of using a source-only check. A failed extension
build is a failed release smoke test.

## Extension SDK verification

The five live extension examples pin published SDK versions in their Cargo,
npm, and uv manifests and lockfiles. The
[`axiom-extension-sdk`](https://github.com/AxiomCore/axiom-extension-sdk)
checkout is needed only for its binding-generation helper, not as a package
source. From a workspace with that checkout beside `examples`, install the
registry packages and regenerate editor bindings with:

```sh
python3.12 scripts/verify_extension_sdks.py --sdk-root ../axiom-extension-sdk --cli laxiom
```

The setup script writes generated Rust bindings under `.axiom/ide`, TypeScript
declarations under `node_modules`, and Python stubs beside the source. The
Python stubs come directly from the SDK's read-only `.acore` boundary scan;
the released CLI still validates Python source at production build time. Those
generated files are ignored; rerun setup when an `.acore` boundary or
`AxiomDeps.toml` permission changes. Update exact package versions and all
affected lockfiles together when testing a new SDK release.

For local reproduction with the workspace CLI:

```sh
AXIOM_BIN=laxiom python3 scripts/verify_acore_examples.py
```

The next CLI release will make `axiom run main.acore --target web` serve
without opening a browser; add `--launch` to open one. Until that release,
set `AXIOM_UI_WEB_NO_OPEN=1` (as the workflow does). Use `--once` for a
compile-only CI check.
