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
