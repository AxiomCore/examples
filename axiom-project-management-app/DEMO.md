# Flowspace demo runbook

## Recommended recording: 3–4 minutes

### 1. Establish the product (0:00–0:35)

Open the web app at a wide viewport. Show the calm sky/lilac hero, live-presence stream, portfolio cards, task list, activity rail, and delivery forecast. Briefly resize to a phone-width viewport or show the same bundle on iOS/Android: the sidebar disappears, cards become a single column, controls become full width, and the content remains touch-friendly.

Message: this is one Acore UI, one typed contract, and one verified delivery model across web, iOS, and Android.

### 2. Show real contract state (0:35–1:15)

Open **New task**, fill the title and description, choose a priority, and create it. Return to the dashboard. The backend validates the request projection and domain invariants, appends the task, emits a normalized `task.created` activity event, and invalidates task/activity/workspace cache identities.

Then click **Resolve blocker**. The `PATCH /tasks/{id}` mutation updates only the three writable fields, changes the workspace summary, emits `task.updated`, and causes the declared queries to revalidate. Point at the backend terminal: the request, state transition, response, and subsequent reads are visible without handwritten API glue.

### 3. Show deterministic portable compute (1:15–1:55)

Click **Assess delivery risk**. The card changes from `0 / Not evaluated` to `50 / Watch` with the calculation `2 blocked · 7 open · deterministic score 50/100`.

Explain the boundary:

- the host supplies only the three authorized forecast fields;
- the extension runs as verified WASM;
- the host validates and atomically applies four authorized writes;
- the same `risk.assess_delivery_risk` export exists in Rust, TypeScript, and Python;
- changing language uses `just use-rust`, `just use-typescript`, or `just use-python`; no Acore screen or action changes.

For a strong visual cut, record the forecast once per profile and show that only the engine label changes.

### 4. Reveal the causal graph (1:55–2:45)

Run:

```bash
laxiom inspect ask "what executes when I press Resolve blocker" frontend
```

The answer proves the button primitive → `Dashboard.complete_focus` → `run resolve_blocker` → `Dashboard.resolve_blocker` chain, with semantic IDs and source evidence. This is static analysis of an interaction before clicking it, not a guessed call graph.

Then run:

```bash
laxiom inspect trace Dashboard.assess_risk frontend --direction downstream
laxiom inspect provenance risk frontend
laxiom inspect authority frontend
```

Show that the risk button reaches the exact extension export, executable artifact, generated interface, and field-level read/write grants. Emphasize what is absent: no network and no arbitrary state access.

Finally show the backend side:

```bash
laxiom inspect operation update_task backend/axiom.axiom
laxiom inspect security backend/axiom.axiom
laxiom inspect data backend/axiom.axiom
```

This reveals endpoint method/path, projections, model fields, task→project relationships, cache facts, writable fields, idempotency, rate limiting, and the redacted assignee classification.

### 5. Make one contract change visible (2:45–3:35)

Capture a baseline:

```bash
laxiom inspect snapshot backend/axiom.axiom --output /tmp/flowspace-before.json
```

For the recording, make one deliberate change to `UpdateTask` in `backend/axiom.acore`. Good options:

1. Remove `workspace:summary` from `invalidates` to demonstrate a stale metric and a semantic cache-policy diff.
2. Remove `progress` from `writableFields` to demonstrate a security-authority reduction and a rejected runtime write.
3. Tighten `taskProgressBounded` from `progress <= 100` to `progress <= 80` to demonstrate how a domain invariant changes acceptance behavior.

Rebuild and capture the new evidence:

```bash
cd backend
laxiom build axiom.acore
cd ..
laxiom inspect snapshot backend/axiom.axiom --output /tmp/flowspace-after.json
laxiom inspect diff /tmp/flowspace-before.json /tmp/flowspace-after.json
```

The compelling point is not just that runtime behavior changes. The exact semantic change and its affected facts are reviewable before deployment. Restore the intended contract after recording.

### 6. Close on evidence, not claims (3:35–3:55)

Run:

```bash
laxiom inspect release-check frontend --enforce
```

Close with: **“AxiomCore makes the product, the runtime boundary, and the proof of what can happen part of the same source.”**

## Recording checklist

- Start the backend before the UI so the first frame is populated.
- Use the Rust profile for the uninterrupted product walkthrough; use short cuts for TypeScript/Python labels.
- Keep the backend debug terminal and Inspector dashboard ready on adjacent desktops.
- Reset the mock server before each take so the activity order and task state are predictable.
- Do not present Jev output as proof. Use deterministic Inspector results for evidence and label Jev as an optional natural-language planner.
