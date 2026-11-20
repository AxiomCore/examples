# simple-backend Flutter client

A Flutter app (Android, iOS, macOS, web) for the FastAPI service in
`../../backend/py-example`. It uses the client generated from that service's Axiom contract:

- register a user (`sdk.pyExample.register(user: UserCreate(...))`)
- log in with the OAuth2 password form and store the bearer token with
  `sdk.pyExample.axiom.setAuthToken('Authorization', token)`; the runtime then attaches it to
  every endpoint that declares that auth method
- create, fetch by id and delete items (authenticated mutations)
- list items with `AxiomBuilder` (cached query, refreshed after each change)
- log out with `sdk.runtime.resetSession()` (clears tokens and session cache)

`POST /login` takes form fields the contract does not describe, so `lib/main.dart` sends the
form body through `sdk.runtime.sendMutation` and decodes the generated `Token` model.

## Layout

| Path | What it is |
| --- | --- |
| `assets/axiom/py-example.axiom` | Contract asset loaded by `AxiomSdk.create()` |
| `AxiomDeps.toml` | Contract name, source and default base URL for the generator |
| `lib/axiom_generated/` | Generated client; do not edit, regenerate |
| `lib/main.dart` | The app |
| `tool/regen.sh` | Rebuilds the contract and regenerates the client |

## Start the backend

```sh
cd ../../backend/py-example
python3 -m venv .venv && . .venv/bin/activate
pip install fastapi uvicorn pyjwt 'pydantic[email]' python-multipart
uvicorn main:app --host 127.0.0.1 --port 8000
```

The service enables CORS for all origins, so the web build talks to it directly.

## Regenerate the client

```sh
tool/regen.sh            # AXIOM=/path/to/axiom to pick a CLI
```

This runs `axiom build` on `../../backend/py-example/axiom.acore` into
`assets/axiom/py-example.axiom`, then
`dart run axiom_flutter_generator:generate --config AxiomDeps.toml --out axiom_generated`.
The build needs the FastAPI extractor (`axiom install --module fastapi-extractor`); CLI 0.156
runs extractors on macOS only.

To use an `axiom-sdk` checkout instead of pub.dev, create an uncommitted
`pubspec_overrides.yaml` (the form is shown at the bottom of `pubspec.yaml`).

## Run

The default base URL is `http://127.0.0.1:8000`. Override it with
`--dart-define=AXIOM_BASE_URL=<url>`.

| Platform | Command |
| --- | --- |
| Web | `flutter run -d chrome` |
| macOS | `flutter run -d macos` |
| iOS simulator | `flutter run -d <simulator id>` |
| Android emulator | `flutter run -d emulator-5554 --dart-define=AXIOM_BASE_URL=http://10.0.2.2:8000` |

Platform setup is already in place: iOS 13.0 and macOS 11.0 deployment targets, the macOS
`com.apple.security.network.client` entitlement, `NSAllowsLocalNetworking` on iOS, Android
minSdk 24 (required by `axiom_flutter`), the `INTERNET` permission and cleartext HTTP for
local backends.

Headless smoke run: build with `--dart-define=AXIOM_EXAMPLE_AUTORUN=true`; the app registers a
fresh user, logs in, creates, lists, fetches and deletes an item, and prints
`AXIOM_EXAMPLE <step> PASS|FAIL ...`.

## Tests

```sh
flutter test
```
