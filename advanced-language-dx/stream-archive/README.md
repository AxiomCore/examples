# Bounded durable archive

This complete example reuses typed resources, managed transactions, event
publishers and durable consumers for a batch sink. It requires a matching source
CLI and the native PostgreSQL 17.11 runtime profile. It does not start a worker
implicitly or treat presentation windows as durable business queues.

From the workspace root:

```sh
axiom check examples/advanced-language-dx/stream-archive/backend/main.acore
axiom check examples/advanced-language-dx/stream-archive/database/schema.acore
axiom build examples/advanced-language-dx/stream-archive/backend/main.acore --out archive.axiom
axiom database runtime prepare \
  --schema examples/advanced-language-dx/stream-archive/database/schema.acore \
  --contract archive.axiom --plan archive.server.json --resource archive \
  --spec examples/advanced-language-dx/stream-archive/backend/runtime-spec.json \
  --out archive.prepared.server.json
axiom server deployment archive.axiom archive.prepared.server.json --output archive.deployment.json
```

Those commands check/prepare artifacts; they do not apply the database or grant
authority. Follow the database signed-release workflow to apply the schema to an
isolated qualified primary. Bind `archive` to `postgres` with a private
`axiom-database-runtime-binding/v1`, matching signed schema/head, TLS and explicit
least-privilege `archive_app` credentials. This profile also requires a currently
successful physical WAL archive; the qualification driver enables and observes
that archive before activating the provider. The generated deployment starts with
empty grants. Grant only the selected resource operations and configure JWT
authentication explicitly.

The `changes` event carries `{key, changes}`. The action validates one to 32 items
and bounded titles. Its private runtime program inserts archive and outbox rows
and one receipt atomically. The stable key is part of the source batch, not an
automatically invented key for each queue delivery. Redelivery must preserve the
key and exact input. Reusing a key with different input conflicts.

Activate delivery with an explicit `axiom-delivery-deployment/v1`, matching plan
hash, Redis configured with AOF/`appendfsync=always`/`noeviction`, a bounded lease
and retention, `publish:publishChanges`, and service authentication references for
`consumer:archiveChanges`. No credentials or database bindings belong in the
message. Enqueue through the existing `server enqueue` command with:

```json
{"kind":"publish","name":"publishChanges","id":"source-batch-1","payload":{"key":"source-batch-1","changes":[{"id":"1","title":"Synthetic event"}]}}
```

Run the native delivery worker with the exact contract, prepared plan, server
deployment and delivery deployment. Queue acknowledgment follows successful
managed action completion. Commit-before-ack interruption permits redelivery;
the receipt replays the committed result without another business/outbox insert.
Returned batch rows use canonical JSON ordering, rather than input ordering.
Receipt retention must cover the source's redelivery window. Separate external
effects need their own idempotency boundary.

The local qualification driver is
`axiom-internal-docs/planning/advanced-language/tests/native_stream_sinks.py`.
It creates disposable TLS PostgreSQL and Redis fixtures and uses the shipping
managed provider/queue, with real process death and stale-lease barriers. It
removes private plans, credentials and database rows on exit. Source preparation
tests are in `axiom-build/tests/m3_stream_sinks.rs`. These test scopes remain
distinct from published SDKs, other providers and mounted mobile applications.
