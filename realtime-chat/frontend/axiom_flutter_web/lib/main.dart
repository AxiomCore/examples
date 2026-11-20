import 'dart:async';

import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/material.dart';

import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart';

late final AxiomSdk sdk;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads assets/axiom/realtime-chat.axiom. Default base URL
  // http://127.0.0.1:8080; override with --dart-define=AXIOM_BASE_URL=<url>.
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

  runApp(const ChatApp());

  if (const bool.fromEnvironment('AXIOM_EXAMPLE_AUTORUN')) {
    await _smoke();
  }
}

/// Opens `/ws`: receive typed `ChatMessage`s, send `{sender, content}` maps.
/// The contract sets `reconnect: "auto"`, so the channel reconnects with
/// back-off after a drop.
AxiomChannel<ChatMessage, Object?> openChat() =>
    sdk.realtimeChat.handleConnectionsChannel();

Future<void> _smoke() async {
  try {
    final channel = openChat();
    final echo = channel.stream
        .where((s) => s.hasError || s.data?.sender == 'smoke')
        .first
        .timeout(const Duration(seconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    channel.send({'sender': 'smoke', 'content': 'hello'});
    final state = await echo;
    await channel.close();
    if (state.hasError) throw state.error!;
    debugPrint(
      'AXIOM_EXAMPLE websocket PASS ${state.data!.sender}: '
      '${state.data!.content} at ${state.data!.timestamp}',
    );
  } catch (e) {
    debugPrint('AXIOM_EXAMPLE websocket FAIL $e');
  }
  debugPrint('AXIOM_EXAMPLE DONE');
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Axiom Flutter chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final _senderCtrl = TextEditingController(text: 'FlutterUser');
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late final AxiomChannel<ChatMessage, Object?> _channel;
  StreamSubscription<AxiomState<ChatMessage>>? _sub;
  bool _online = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _channel = openChat();
    _sub = _channel.stream.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.hasError) {
          _online = false;
          _error = state.error?.message;
        } else {
          _online = true;
          _error = null;
        }
        if (state.hasData) _messages.add(state.data!);
      });
      if (state.hasData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel.close();
    _senderCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _channel.send({'sender': _senderCtrl.text, 'content': text});
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final status = _error != null
        ? ('Error: $_error', const Color(0xFFDC2626))
        : _online
        ? ('Online', const Color(0xFF16A34A))
        : ('Connecting...', const Color(0xFFF59E0B));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Axiom Flutter chat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                status.$1,
                style: TextStyle(color: status.$2, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => _Bubble(
                    message: _messages[i],
                    isMe: _messages[i].sender == _senderCtrl.text,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _senderCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(labelText: 'Message'),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isSystem = message.sender == 'System';
    return Align(
      alignment: isSystem
          ? Alignment.center
          : isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe && !isSystem ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSystem)
              Text(
                message.sender.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isMe
                      ? const Color(0xFFDBEAFE)
                      : const Color(0xFF94A3B8),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                fontStyle: isSystem ? FontStyle.italic : null,
                color: isMe && !isSystem
                    ? Colors.white
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
