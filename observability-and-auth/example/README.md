# Auth example (Flutter)

Maintainer fixture for auth in `axiom_flutter`. The contract in `../axiom.acore` amends the
synthetic FastAPI fixture in `../test_server.py` (see `../README.md` for its security limits:
loopback only, fixed public test keys, never deploy).

| Button | What it does |
| --- | --- |
| 1. Log in and set JWT | `POST /login`, then `sdk.authObsTest.axiom.setAuthToken('Authorization', token)` |
| 2. Set API key (header) | `setAuthToken('x-api-key', 'development-only-api-key')` |
| 3. Set API key (query) | `setAuthToken('api_key', 'development-only-api-key')` |
| Log out | `sdk.runtime.resetSession()`: cancels calls, clears session cache and tokens |
| Test: ... | Calls `/protected/jwt`, `/protected/api-key-header`, `/protected/api-key-query`, `/protected/multi` and shows each state |

The runtime attaches each stored token to the requests whose contract auth method needs
it; the app never builds headers itself.

## Layout

| Path | What it is |
| --- | --- |
| `assets/axiom/auth_obs_test.axiom` | Contract asset loaded by `AxiomSdk.create()` |
| `AxiomDeps.toml` | Contract name, source and default base URL for the generator |
| `lib/axiom_generated/` | Generated client; do not edit, regenerate |
| `lib/main.dart` | The demo screen |
| `tool/regen.sh` | Rebuilds the contract and regenerates the client |

## Start the backend

From `..` (examples/observability-and-auth), with Python 3.12:

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install --require-hashes -r requirements.lock
AXIOM_AUTH_FIXTURE_DEV=1 .venv/bin/python test_server.py    # 127.0.0.1:8000
```

`AXIOM_AUTH_FIXTURE_PORT` changes the port.

## Regenerate the client

```sh
tool/regen.sh            # AXIOM=/path/to/axiom to pick a CLI
```

This runs `axiom build ../axiom.acore --out assets/axiom/auth_obs_test.axiom` and then
`dart run axiom_flutter_generator:generate --config AxiomDeps.toml --out axiom_generated`.
The build needs the FastAPI extractor and PyJWT importable by it (`axiom install --module fastapi-extractor`); CLI 0.156
runs extractors on macOS only.

To use an `axiom-sdk` checkout instead of pub.dev, create an uncommitted
`pubspec_overrides.yaml` (the form is shown at the bottom of `pubspec.yaml`).

## Run

The default base URL is `http://127.0.0.1:8000`. Override it with
`--dart-define=AXIOM_BASE_URL=<url>`.

| Platform | Command |
| --- | --- |
| macOS | `flutter run -d macos` |
| iOS simulator | `flutter run -d <simulator id>` |
| Android emulator | `flutter run -d emulator-5554 --dart-define=AXIOM_BASE_URL=http://10.0.2.2:8000` |
| Web | `flutter run -d chrome --web-browser-flag=--disable-web-security` |

The auth fixture sends no CORS headers, so the web build needs a browser without
web security for local runs, or a CORS middleware in front of the server.

Platform setup is already in place: iOS 13.0 and macOS 11.0 deployment targets, the macOS
`com.apple.security.network.client` entitlement, `NSAllowsLocalNetworking` on iOS, and the
Android `INTERNET` permission with cleartext HTTP allowed for local backends.

Headless smoke run: build with `--dart-define=AXIOM_EXAMPLE_AUTORUN=true`; the app logs in, sets
all three credentials and calls the four protected routes, printing
`AXIOM_EXAMPLE login|jwt|api-key-header|api-key-query|multi PASS|FAIL ...`.

## Tests

```sh
flutter test
```
