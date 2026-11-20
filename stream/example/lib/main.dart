import 'dart:async';

import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/material.dart';

import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart' as models;

late final AxiomSdk sdk;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads assets/axiom/stream.axiom. Default base URL http://127.0.0.1:8000;
  // override with --dart-define=AXIOM_BASE_URL=<url>.
  try {
    sdk = await AxiomSdk.create();
  } catch (e) {
    debugPrint('AXIOM_EXAMPLE init FAIL $e');
    debugPrint('AXIOM_EXAMPLE DONE');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('$e'))),
      ),
    );
    return;
  }

  runApp(const MaterialApp(home: StreamTester()));

  if (const bool.fromEnvironment('AXIOM_EXAMPLE_AUTORUN')) {
    await _smoke();
  }
}

/// Frames arrive as `ChatMessage` when the contract types the stream, or as
/// JSON maps when it does not; accept both.
models.ChatMessage chatMessage(Object? frame) =>
    frame is models.ChatMessage ? frame : models.ChatMessage.fromJson(frame);

/// Opens the bidirectional `/ws/chat` channel: send `String`, receive `ChatMessage`.
AxiomChannel<models.ChatMessage, String> openChat() {
  return sdk.runtime.openChannel<models.ChatMessage, String>(
    namespace: 'stream',
    endpointId: StreamModule.endpointIds['websocket_endpoint']!,
    method: 'WS',
    path: '/ws/chat',
    decoder: chatMessage,
    reconnect: AxiomReconnectPolicy.auto,
  );
}

Future<void> _smoke() async {
  Future<void> run(String name, Future<String> Function() body) async {
    try {
      debugPrint('AXIOM_EXAMPLE $name PASS ${await body()}');
    } catch (e) {
      debugPrint('AXIOM_EXAMPLE $name FAIL $e');
    }
  }

  const limit = Duration(seconds: 20);
  await run('chunks', () async {
    final msgs = await sdk.stream
        .streamChunksStream()
        .map(chatMessage)
        .toList()
        .timeout(limit);
    return '${msgs.length} frames, last "${msgs.last.text}"';
  });
  await run('sse', () async {
    final msgs = await sdk.stream
        .streamSseStream()
        .map(chatMessage)
        .toList()
        .timeout(limit);
    return '${msgs.length} frames, last "${msgs.last.text}"';
  });
  await run('websocket', () async {
    final channel = openChat();
    final reply = channel.stream
        .firstWhere((s) => s.hasData || s.hasError)
        .timeout(limit);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    channel.send('hello');
    final state = await reply;
    await channel.close();
    if (state.hasError) throw state.error!;
    return '"${state.data!.text}"';
  });
  debugPrint('AXIOM_EXAMPLE DONE');
}

class StreamTester extends StatefulWidget {
  const StreamTester({super.key});

  @override
  State<StreamTester> createState() => _StreamTesterState();
}

class _StreamTesterState extends State<StreamTester> {
  final List<String> _logs = [];
  StreamSubscription<Object?>? _subscription;
  AxiomChannel<models.ChatMessage, String>? _channel;
  final TextEditingController _wsController = TextEditingController();

  void _log(String msg) => setState(() => _logs.insert(0, msg));

  void _reset() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.close();
    _channel = null;
    setState(_logs.clear);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.close();
    _wsController.dispose();
    super.dispose();
  }

  /// HTTP chunked NDJSON: one `ChatMessage` per line. Cancelling the
  /// subscription cancels the request.
  void _testHttpStream() {
    _reset();
    _log('Starting HTTP chunked stream...');
    _subscription = sdk.stream
        .streamChunksStream()
        .map(chatMessage)
        .listen(
          (msg) => _log('[CHUNK] ${msg.user}: ${msg.text}'),
          onError: (Object e) => _log('Error: $e'),
          onDone: () => _log('Stream complete'),
        );
  }

  /// Server-sent events.
  void _testSseStream() {
    _reset();
    _log('Starting SSE stream...');
    _subscription = sdk.stream
        .streamSseStream()
        .map(chatMessage)
        .listen(
          (msg) => _log('[SSE] ${msg.user}: ${msg.text}'),
          onError: (Object e) => _log('Error: $e'),
          onDone: () => _log('Stream complete'),
        );
  }

  /// Bidirectional WebSocket with automatic reconnect.
  void _testWebSocket() {
    _reset();
    final channel = openChat();
    _channel = channel;
    _log('WebSocket connected');
    _subscription = channel.stream.listen((state) {
      if (state.hasData) {
        _log('[WS RECV] ${state.data!.user}: ${state.data!.text}');
      } else if (state.hasError) {
        _log('[WS ERROR] ${state.error?.message}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Axiom streams and WebSocket')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testHttpStream,
                  child: const Text('HTTP stream'),
                ),
                ElevatedButton(
                  onPressed: _testSseStream,
                  child: const Text('SSE stream'),
                ),
                ElevatedButton(
                  onPressed: _testWebSocket,
                  child: const Text('Connect WS'),
                ),
              ],
            ),
            const Divider(),
            if (_channel != null)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _wsController,
                      decoration: const InputDecoration(
                        hintText: 'Send message to WS...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      _channel!.send(_wsController.text);
                      _log('[WS SENT] ${_wsController.text}');
                      _wsController.clear();
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black,
                width: double.infinity,
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, i) => Text(
                    _logs[i],
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
