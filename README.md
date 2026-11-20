# AxiomCore examples

Public, runnable examples for the [AxiomCore](https://github.com/AxiomCore/AxiomCore) CLI, Acore language, client SDKs, and UI runtime. These use synthetic data and local services. They are learning and validation fixtures, not production templates or a promise that every target is stable.

Start with a single directory; each example owns its dependencies and commands. The status below describes the example's intended use, not the overall maturity of its underlying product capability. Check the [public support matrix](https://docs.axiomcore.dev/introduction/support-matrix) before choosing a production integration.

| Example | Status | What it demonstrates |
| --- | --- | --- |
| [`domain-commerce`](domain-commerce) | Start here | Domain entities, invariants, projections, and semantic change review |
| [`domain-support`](domain-support) | Start here | Small audience-specific domain projection |
| [`domain-inference-fastapi`](domain-inference-fastapi) | Guided | FastAPI/Pydantic extraction and domain promotion |
| [`security-mode-v1`](security-mode-v1) | Guided | Passing audit fixture and intentionally rejected strict fixture |
| [`simple-backend`](simple-backend) | Integration | FastAPI/Go service with web, React, and Flutter consumers; the [Flutter client](simple-backend/frontend/axiom_flutter_web) registers, logs in and manages items on Android, iOS, macOS and web |
| [`offline-first-feed`](offline-first-feed) | Integration | Cached feed and offline/online consumer behavior (web client); for Flutter see [`flutter-offline-first`](flutter-offline-first) |
| [`flutter-quickstart`](flutter-quickstart) | Start here (Flutter) | The Flutter quickstart's finished app; more Flutter examples in [Flutter examples](#flutter-examples) |
| [`realtime-chat`](realtime-chat) | Integration | Go WebSocket chat with multiple client targets; the [Flutter client](realtime-chat/frontend/axiom_flutter_web) uses a typed `AxiomChannel` on Android, iOS, macOS and web |
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
| [`rpc`](rpc), [`stream`](stream), [`observability-and-auth`](observability-and-auth) | Maintainer fixtures | Flutter apps (Android, iOS, macOS, web) for model RPCs, HTTP chunked/SSE/WebSocket streams, and JWT/API-key auth against small FastAPI servers (`stream`'s contract is native Acore and rebuilds on any OS) |

## First run

Install the current [Axiom CLI](https://github.com/AxiomCore/AxiomCore#start-locally), then validate a self-contained example:

```sh
cd domain-commerce
axiom domain validate commerce-v1.acore
axiom diff commerce-v1.acore commerce-v2.acore --format semantic
```

The second contract intentionally removes a projected field; treat that as a consumer-breaking change even if the current semantic output does not classify it automatically. `axiom build` requires a configured local CLI/runtime environment and is not part of this minimal smoke test. For FastAPI extraction, use [`domain-inference-fastapi`](domain-inference-fastapi/README.md) and install its Python dependencies first. For a full application, follow the README in its directory and run the backend and frontend in separate terminals.

## Flutter examples

Every Flutter example uses `axiom_flutter` 0.150.0 (and `axiom_flutter_auth` 0.150.0 where
noted) from pub.dev with Axiom CLI 0.156.0, has `android`, `ios`, `macos` and `web` folders set up
(minSdk 24, `INTERNET`, iOS 13.0, macOS 11.0 with the network-client entitlement,
`NSAllowsLocalNetworking`), commits its generated client, and has a README with the commands for
each platform and what you should see. `tool/regen.sh` rebuilds the contract and regenerates the
client. Building with `--dart-define=AXIOM_EXAMPLE_AUTORUN=true` makes an app run its steps once
and print `AXIOM_EXAMPLE <step> PASS|FAIL` lines for headless checks.

| Example | What it shows | Backend | Platforms built | Platforms run | Regenerate on |
| --- | --- | --- | --- | --- | --- |
| [`flutter-quickstart`](flutter-quickstart) | The talks app of the [Flutter quickstart](https://docs.axiomcore.dev/getting-started/quickstart-flutter/), identical to the page | Acore | web, Android (APK) | web (headless Chrome) | any OS |
| [`flutter-auth`](flutter-auth) | Sign-up, sign-in, session restore, sign-out with `axiom_flutter_auth` against `axiom auth emulate`; token scoped to one namespace | Acore (guarded endpoint) + local auth emulator | web, Android (APK) | web (headless Chrome) | any OS |
| [`flutter-offline-first`](flutter-offline-first) | Cache-first and stale-while-revalidate lists, pull-to-refresh, renders from the persistent cache after a restart with the backend down | Acore | web, Android (APK) | web (headless Chrome) | any OS |
| [`flutter-minimal`](flutter-minimal) | Smallest app (one query) with measured release sizes for 0.150.0 | Acore | web, Android (APK, release per ABI) | web (headless Chrome) | any OS |
| [`stream/example`](stream/example) | HTTP chunked, SSE and a bidirectional WebSocket (`AxiomChannel`) | FastAPI; contract in native Acore | web, Android (APK) | web (headless Chrome) | any OS |
| [`rpc/example`](rpc/example) | Model RPCs | FastAPI (extracted contract) | web, Android (APK) | not re-run in this cycle | macOS (FastAPI extractor) |
| [`observability-and-auth/example`](observability-and-auth/example) | JWT and API-key auth, tracing | FastAPI (extracted contract) | web, Android (APK) | web (earlier cycle) | macOS (FastAPI extractor) |
| [`simple-backend/frontend/axiom_flutter_web`](simple-backend/frontend/axiom_flutter_web) | Register, log in, manage items | FastAPI / Go (extracted contract) | web, Android (APK) | web, partly (POST /items answers 500: `Item.dodo` is required but never set) | macOS (extractor) |
| [`realtime-chat/frontend/axiom_flutter_web`](realtime-chat/frontend/axiom_flutter_web) | Typed WebSocket chat | Go (extracted contract) | web, Android (APK) | web (earlier cycle) | macOS (Go extractor) |

"Platforms run" lists what has been run on a Linux box without emulators. iOS, macOS and the
Android emulator are set up but must be run on a Mac or a machine with an emulator. CLI 0.156.0
runs the FastAPI and Go extractors on macOS only, so contracts that `amends` a FastAPI or Go app
can only be rebuilt there; the Acore-based examples rebuild anywhere. To build an example against
an `axiom-sdk` checkout, add an uncommitted `pubspec_overrides.yaml` with path dependencies.

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
build is a failed release smoke test. CI first fetches each project's committed
Cargo lockfile dependencies from crates.io because the CLI compiles guests
offline; that fetch does not change the locks or substitute local SDK sources.

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
