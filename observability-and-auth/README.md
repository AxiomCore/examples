# Local authentication example

This synthetic fixture accepts loopback clients only. The backend verifies every protected HTTP request independently of the Axiom SDK. `/login` issues a fixed synthetic identity without authenticating a user. Never deploy this login, reuse these public keys, or put a production HMAC signing secret in a client contract.

Use Python 3.12 and the committed hash-locked dependencies, from this directory:

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install --require-hashes -r requirements.lock
AXIOM_AUTH_FIXTURE_DEV=1 .venv/bin/python test_server.py
```

The supported launch binds `127.0.0.1:8000`, disables access logs and proxy-header rewriting, and requires `AXIOM_AUTH_FIXTURE_DEV=1`. `AXIOM_AUTH_FIXTURE_HOST` must be loopback. Do not put a reverse proxy in front of this fixture. An ASGI request boundary also rejects non-loopback clients and disabled development mode. Alternate ASGI launchers must disable proxy-header rewriting and access logging; the query-redaction filter covers standard Uvicorn access logs, not arbitrary proxy or application loggers.

The public fixture API key is `development-only-api-key`. Its public JWT signing key is declared in `test_server.py` and `axiom.acore`. Keys in this example have no production privileges. The UI sets these same fixture values. Do not print issued tokens or query API keys in logs.

| Route | Server policy | Rejection |
| --- | --- | --- |
| `/protected/jwt` | Verified HS256 signature; integer expiry; nonempty subject; list of nonempty scope strings; `items:read` scope | Missing/invalid credential: 401; missing scope: 403 |
| `/protected/api-key-header` | Exact fixture key in `x-api-key` | 403 |
| `/protected/api-key-query` | Exact fixture key in `api_key` | 403 |
| `/protected/multi` | OR: verified JWT with required claim shapes or exact header API key; no additional scope required | Neither valid: 401 |

For OR, one valid method succeeds even when the other supplied method is invalid. JWT verification also checks optional `nbf`/`iat` when present. This fixture introduces no issuer/audience policy. A production service needs its own server-held keys, issuer/audience and user authorization policy; client interception cannot provide that boundary. Signatures verify integrity/authenticity, not confidentiality.

Run direct HTTP regressions (they bypass every Axiom client):

```sh
.venv/bin/python -m unittest discover -s . -p test_auth.py -v
```

Keep client validation separate: `axiom check axiom.acore --json` checks the current contract; the Flutter widget test remains under `example/test/`. Generate/rebuild the contract and SDK for the selected runtime before a client integration run. A widget rendering test alone does not prove network authorization. The committed `.axiom` was rebuilt from this contract with the corrected CLI; its login endpoint ID is aligned in the generated Dart adapter. Rebuild to a named output such as `backend.axiom`, then copy the exact bytes to `.axiom` for this example’s asset configuration.

Dependency references: [PyJWT verification](https://pyjwt.readthedocs.io/en/stable/usage.html), [FastAPI lifespan testing](https://fastapi.tiangolo.com/advanced/testing-events/).
