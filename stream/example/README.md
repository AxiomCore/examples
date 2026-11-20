# Streams example (Flutter)

Streaming in `axiom_flutter`: HTTP chunked, server-sent events and a WebSocket. The server is
the FastAPI app in `../test_server.py`. Its contract is `../contract/main.acore`, native Acore
that describes the same three routes with the `ChatMessage {user, text}` model, so the contract
builds on any OS without the FastAPI extractor (the FastAPI app still serves every request; the
managed bodies in the Acore file are never run). `../axiom.acore` is the older form, which
`amends` the FastAPI app and needs the extractor (macOS only with CLI 0.156.0); it is kept for
reference and is not used by the app.

Why the server is not Acore: with CLI 0.156.0 a managed stream action emits exactly one frame per
call, and a WebSocket endpoint behind a global `cors(...)` refuses the browser's upgrade, so the
five-frame streams and the unauthenticated browser WebSocket of this example cannot be served by an
Acore backend yet.

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
tool/regen.sh            # AXIOM=/path/to/axiom to pick a CLI; works on Linux, macOS and Windows
```

This runs `axiom check` and `axiom build` on `../contract/main.acore`, writes
`assets/axiom/stream.axiom` and then runs
`dart run axiom_flutter_generator:generate --config AxiomDeps.toml --out axiom_generated`.
When you change `../test_server.py`, change `../contract/main.acore` to match.

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
`com.apple.security.network.client` entitlement, `NSAllowsLocalNetworking` on iOS,
Android minSdk 24 (required by `axiom_flutter`), the `INTERNET` permission and cleartext HTTP for local backends.

Headless smoke run: build with `--dart-define=AXIOM_EXAMPLE_AUTORUN=true`; the app reads both streams and
sends one WebSocket message at start-up. Expected (verified in headless Chrome against the FastAPI server):

```text
AXIOM_EXAMPLE chunks PASS 5 frames, last "Message chunk #5"
AXIOM_EXAMPLE sse PASS 5 frames, last "Event 5"
AXIOM_EXAMPLE websocket PASS "Received: hello"
AXIOM_EXAMPLE DONE
```

## Tests

```sh
flutter test
```
