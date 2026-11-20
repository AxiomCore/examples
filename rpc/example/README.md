# RPC example (Flutter)

Maintainer fixture for model RPCs in `axiom_flutter`. The contract in `../axiom.acore`
amends the FastAPI app in `../test_server.py` and declares an RPC on the `Person`
model:

```
Person.rpcs.get_contacts(limit: int32)
  -> POST /collections  body {max_results: $args.limit, person_id: $this.id}
```

The app shows one person and a button. Pressing it calls `person.getContacts(sdk.rpc, limit: 10)`
through `AxiomMutationBuilder` and shows the server's message.

The generator emits `getContacts` as an extension on the `Person` model, because the
contract declares it as a model RPC (`Person.rpcs.get_contacts`).

## Layout

| Path | What it is |
| --- | --- |
| `assets/axiom/rpc.axiom` | Contract asset loaded by `AxiomSdk.create()` |
| `AxiomDeps.toml` | Contract name, source and default base URL for the generator |
| `lib/axiom_generated/` | Generated client; do not edit, regenerate |
| `lib/main.dart` | The demo screen |
| `tool/regen.sh` | Rebuilds the contract and regenerates the client |

## Start the backend

```sh
cd ..            # examples/rpc
python3 -m venv .venv && . .venv/bin/activate
pip install fastapi uvicorn
uvicorn test_server:app --host 127.0.0.1 --port 8000
```

## Regenerate the client

```sh
tool/regen.sh            # AXIOM=/path/to/axiom to pick a CLI
```

This runs `axiom build ../axiom.acore --out assets/axiom/rpc.axiom` and then
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
| macOS | `flutter run -d macos` |
| iOS simulator | `flutter run -d <simulator id>` |
| Android emulator | `flutter run -d emulator-5554 --dart-define=AXIOM_BASE_URL=http://10.0.2.2:8000` |
| Web | `flutter run -d chrome --web-browser-flag=--disable-web-security` |

The FastAPI test server sends no CORS headers, so the web build needs a browser without
web security for local runs, or a CORS middleware in front of the server.

Platform setup is already in place: iOS 13.0 and macOS 11.0 deployment targets, the macOS
`com.apple.security.network.client` entitlement, `NSAllowsLocalNetworking` on iOS,
Android minSdk 24 (required by `axiom_flutter`), the `INTERNET` permission and cleartext HTTP for local backends.

Headless smoke run: build with `--dart-define=AXIOM_EXAMPLE_AUTORUN=true`; the app calls the RPC
once at start-up and prints `AXIOM_EXAMPLE rpc PASS <response>` or `... FAIL <error>`.

## Tests

```sh
flutter test
```
