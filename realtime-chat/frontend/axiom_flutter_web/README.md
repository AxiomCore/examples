# realtime-chat Flutter client

A Flutter chat app (Android, iOS, macOS, web) for the Go WebSocket server in
`../../backend/go-chat`. Every client connected to `/ws` receives every message.

The contract (`../../backend/go-chat/axiom.acore`) declares `handleConnections` as a
bidirectional WebSocket returning `ChatMessage {sender, content, timestamp}` with
`reconnect: "auto"`. The generated client exposes it as a typed channel:

```dart
final channel = sdk.realtimeChat.handleConnectionsChannel(); // AxiomChannel<ChatMessage, Object?>
channel.stream.listen((state) { if (state.hasData) print(state.data!.content); });
channel.send({'sender': 'me', 'content': 'hello'});
await channel.close();
```

The app shows the connection state, the message list, and a name and message field.

## Layout

| Path | What it is |
| --- | --- |
| `assets/axiom/realtime-chat.axiom` | Contract asset loaded by `AxiomSdk.create()` |
| `AxiomDeps.toml` | Contract name, source and default base URL for the generator |
| `lib/axiom_generated/` | Generated client; do not edit, regenerate |
| `lib/main.dart` | The app |
| `tool/regen.sh` | Rebuilds the contract and regenerates the client |

## Start the backend

```sh
cd ../../backend/go-chat
go run .            # listens on :8080
```

The server accepts WebSocket upgrades from any origin, so the web build connects directly.

## Regenerate the client

```sh
tool/regen.sh            # AXIOM=/path/to/axiom to pick a CLI
```

This runs `axiom build` on `../../backend/go-chat/axiom.acore` into
`assets/axiom/realtime-chat.axiom`, then
`dart run axiom_flutter_generator:generate --config AxiomDeps.toml --out axiom_generated`.
The build needs the Go extractor (`axiom install --module go-extractor`); CLI 0.156 runs
extractors on macOS only.

To use an `axiom-sdk` checkout instead of pub.dev, create an uncommitted
`pubspec_overrides.yaml` (the form is shown at the bottom of `pubspec.yaml`).

## Run

The default base URL is `http://127.0.0.1:8080` (the runtime switches to `ws://` for the
socket). Override it with `--dart-define=AXIOM_BASE_URL=<url>`.

| Platform | Command |
| --- | --- |
| Web | `flutter run -d chrome` |
| macOS | `flutter run -d macos` |
| iOS simulator | `flutter run -d <simulator id>` |
| Android emulator | `flutter run -d emulator-5554 --dart-define=AXIOM_BASE_URL=http://10.0.2.2:8080` |

Open two windows (for example web and macOS) to see messages arrive in both.

Platform setup is already in place: iOS 13.0 and macOS 11.0 deployment targets, the macOS
`com.apple.security.network.client` entitlement, `NSAllowsLocalNetworking` on iOS, Android
minSdk 24 (required by `axiom_flutter`), the `INTERNET` permission and cleartext traffic for
local backends.

Headless smoke run: build with `--dart-define=AXIOM_EXAMPLE_AUTORUN=true`; the app opens a
second channel, sends one message and prints `AXIOM_EXAMPLE websocket PASS|FAIL ...` when the
broadcast comes back.

## Tests

```sh
flutter test
```
