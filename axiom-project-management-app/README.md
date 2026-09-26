# Flowspace — AxiomCore project-management demo

Flowspace is a responsive, contract-driven project-management application built entirely with Acore. It is designed as the primary AxiomCore product demo: the interface looks like a real planning product, the backend is stateful, writes emit activity, cache invalidation is declared in the contract, and one capability-scoped extension can be implemented in Rust, TypeScript, or Python without changing the UI.

## What is in the example

- Four responsive routes: dashboard, create task, weekly timeline, and project details.
- Reusable local Acore components and split ACSS tokens, components, pages, motion, and responsive rules.
- A stateful Acore mock backend with five models, relationships, projections, invariants, eight endpoints, cache policy, retries, WebSocket presence, mutations, state events, strict security, writable-field limits, rate limits, idempotency, and personal-data redaction.
- A deterministic delivery-risk extension behind one stable `risk` alias.
- Equivalent Rust, TypeScript, and Python implementations with the same export and UI authority.
- AxiomInspector-ready frontend behavior, extension provenance/authority, and backend contract facts.

## Run it

From this directory:

```bash
just use-rust
```

Start the stateful backend in terminal one:

```bash
just mock
```

Start a target in terminal two:

```bash
just web
# or
just ios
# or
just android
```

`just check` compiles the same UI and extension boundary for web, Android, and iOS without launching a host.

The local `.axiom` artifact is intentionally unsigned for development, so `AUI059` is expected. Production releases must use an Axiom Cloud-signed contract.

## Switch the extension language

The UI always imports:

```acore
use extension RiskAnalyzer from "risk" export "assess_delivery_risk"
```

Choose the implementation before launching:

```bash
just use-rust
just use-typescript
just use-python
```

Rust builds with the pinned Rust toolchain. TypeScript and Python deliberately fail closed unless the exact Axiom-managed compilers are supplied:

```bash
export AXIOM_TYPESCRIPT_TSC=/absolute/path/to/typescript-7.0.2/tsc
export AXIOM_TYPESCRIPT_ESBUILD=/absolute/path/to/esbuild-0.28.2
export AXIOM_TYPESCRIPT_JAVY=/absolute/path/to/javy-9.1.0
export AXIOM_PYTHON_COMPILER=/absolute/path/to/python3.12.11
```

The three sources are in `frontend/sandbox/`. Each implementation receives the contract-projected `WorkspaceSummary` as its input and derives the same bounded score from its task counts. The extension may read the four existing forecast fields only to obtain the authorized UI snapshot revision, and it may write only those same four result fields. It has no network, filesystem, process, clock, or undeclared UI authority.

## Inspect it

Launch the local dashboard:

```bash
just inspect
```

Useful deterministic queries:

```bash
laxiom inspect ask "what executes when I press Resolve blocker" frontend
laxiom inspect ask "what executes when I press Assess delivery risk" frontend
laxiom inspect trace Dashboard.assess_risk frontend --direction downstream
laxiom inspect provenance risk frontend
laxiom inspect authority frontend
laxiom inspect operation update_task backend/axiom.axiom
laxiom inspect data backend/axiom.axiom
laxiom inspect cache backend/axiom.axiom
laxiom inspect security backend/axiom.axiom
laxiom inspect release-check frontend --enforce
```

The deterministic planner answers from canonical facts. If `AI_GATEWAY_API_KEY` is already available through the local environment, Jev can help select the same bounded facts for a natural-language question:

```bash
laxiom inspect ask \
  "what executes when I press Resolve blocker" frontend \
  --planner jev --allow-remote
```

Jev is a planner, not evidence: the question and a bounded semantic candidate list may be sent remotely, while the returned plan is validated locally and every answer still comes from deterministic Inspector facts.

See [DEMO.md](DEMO.md) for the recording sequence and the contract-change segment.
