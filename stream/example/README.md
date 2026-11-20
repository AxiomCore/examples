# Streams example (Flutter)

Maintainer fixture for streaming in `axiom_flutter`. The contract in `../axiom.acore` amends
the FastAPI app in `../test_server.py` and types three streaming endpoints with the
`ChatMessage {user, text}` model:

| Endpoint | Kind | Dart API used |
| --- | --- | --- |
| `GET /stream/chunks` | HTTP chunked NDJSON, 5 frames | `sdk.stream.streamChunksStream()` (typed `Stream`, cancelling the subscription cancels the request) |
| `GET /stream/sse` | Server-sent events, 5 events | `sdk.stream.streamSseStream()` |
| `WS /ws/chat` | Bidirectional WebSocket, echoes each text message, `reconnect: "auto"` | `AxiomChannel<ChatMessage, String>` with `AxiomReconnectPolicy.auto` |

The app has one button per endpoint and a log view; when the WebSocket is open a text
field sends messages up the channel.

`lib/main.dart` opens the channel with `sdk.runtime.openChannel` and maps frames with a
`chatMessage()` helper, so it works whether or not the contract asset carries the stream
types (the generated `websocketEndpointChannel()` is typed from the contract).

## Layout

| Path | What it is |
| --- | --- |
| `assets/axiom/stream.axiom` | Contract asset loaded by `AxiomSdk.create()` |
| `AxiomDeps.toml` | Contract name, source and default base URL for the generator |
| `lib/axiom_generated/` | Generated client; do not edit, regenerate |
| `lib/main.dart` | The demo screen |
| `tool/regen.sh` | Rebuilds the contract and regenerates the client |

## Start the backend

```sh
cd ..            # examples/stream
python3 -m venv .venv && . .venv/bin/activate
pip install fastapi 'uvicorn[standard]'
uvicorn test_server:app --host 127.0.0.1 --port 8000
```

## Regenerate the client

```sh
tool/regen.sh            # AXIOM=/path/to/axiom to pick a CLI
```

This runs `axiom build ../axiom.acore --out assets/axiom/stream.axiom` and then
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
| Web | `flutter run -d chrome` |

The FastAPI test server allows all origins (CORS middleware), so `flutter run -d chrome` works
without extra flags.

Platform setup is already in place: iOS 13.0 and macOS 11.0 deployment targets, the macOS
`com.apple.security.network.client` entitlement, `NSAllowsLocalNetworking` on iOS, and the
Android minSdk 24 (required by `axiom_flutter`), the `INTERNET` permission and cleartext HTTP for local backends.

Headless smoke run: build with `--dart-define=AXIOM_EXAMPLE_AUTORUN=true`; the app reads both streams and
sends one WebSocket message at start-up, printing `AXIOM_EXAMPLE chunks|sse|websocket PASS|FAIL ...`.

## Tests

```sh
flutter test
```
