// GENERATED CODE - DO NOT EDIT.
// axiom_flutter_generator 0.150.0
// stream: streaming-test 1.0.0 variant default schema d0cbf11bb031

import 'dart:convert';
import 'dart:typed_data';

import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models.dart' as models;

/// Contract configuration written by `axiom pull`.
abstract final class AxiomDefaultConfig {
  static const AxiomConfig config = AxiomConfig(
    contracts: {
      'stream': AxiomContractConfig(
        baseUrl: 'http://127.0.0.1:8000',
        assetPath: 'assets/axiom/stream.axiom',
      ),
    },
  );

  /// sha256 of each contract asset at generation time.
  static const Map<String, String> contractSha256 = {
    'stream':
        'c30c65487763baf386e6e4a4c9a120d7b5602bbc5e0d7a52e4ab653b1e48d144',
  };
}

/// Entry point of the generated client.
class AxiomSdk {
  /// Wraps an already initialized [runtime] (tests, custom start-up).
  AxiomSdk.fromRuntime(
    this.runtime, [
    this.initResult = const AxiomInitResult(ok: true),
  ]) : stream = StreamModule._(runtime, 'stream');

  final AxiomRuntime runtime;

  /// Outcome of runtime start-up and contract loading.
  final AxiomInitResult initResult;

  /// Endpoints of the `stream` contract.
  final StreamModule stream;

  /// Starts the runtime and loads the contracts.
  ///
  /// Base URL priority: [baseUrlOverrides] > [environment] (or the
  /// config's, else `--dart-define=AXIOM_ENV` / `AXIOM_BASE_URL`) >
  /// the generated default. Throws when initialization fails.
  static Future<AxiomSdk> create({
    AxiomConfig? config,
    AxiomEnvironment? environment,
    Map<String, String>? baseUrlOverrides,
    AxiomAssetLoader? assetLoader,
  }) async {
    final base = config ?? AxiomDefaultConfig.config;
    final cfg = base.copyWith(
      environment:
          environment ?? base.environment ?? AxiomEnvironment.fromDartDefines(),
      baseUrlOverrides: baseUrlOverrides,
    );
    final runtime = AxiomRuntime();
    runtime.debug = cfg.debug;
    AxiomInitResult result;
    try {
      result = await runtime.initialize(cfg, assetLoader: assetLoader);
    } on UnimplementedError {
      // Runtime package without initialize(): legacy start-up.
      result = await _legacyInit(runtime, cfg, assetLoader);
    }
    result.requireOk();
    return AxiomSdk.fromRuntime(runtime, result);
  }
}

/// Client for the `stream` contract (streaming-test 1.0.0).
class StreamModule {
  StreamModule._(this._runtime, this._namespace)
    : axiom = StreamModuleAxiomNamespace._(_runtime, _namespace);

  /// Binds this client to another namespace of [runtime], for example the same
  /// contract loaded a second time with a different base URL.
  StreamModule(AxiomRuntime runtime, String namespace)
    : this._(runtime, namespace);

  final AxiomRuntime _runtime;
  final String _namespace;

  /// Auth tokens and cache control for this namespace.
  final StreamModuleAxiomNamespace axiom;

  /// Endpoint ids by contract endpoint name.
  static const Map<String, int> endpointIds = {
    'stream_chunks': 3842853571,
    'stream_sse': 2163966778,
    'websocket_endpoint': 3385426738,
  };

  /// Endpoint ids by contract cache identity.
  static const Map<String, List<int>> cacheIdentities = {};

  /// Auth method names declared by the contract.
  static const List<String> authMethods = [];

  /// `GET /stream/chunks` (http_stream).
  AxiomQuery<models.ChatMessage> streamChunks({AxiomCallOptions? options}) {
    return _streamQuery<models.ChatMessage>(
      '${_namespace}_3842853571_stream_${jsonEncode(<String, dynamic>{})}',
      _runtime,
      (extra) => _runtime.callStream(
        namespace: _namespace,
        endpointId: 3842853571,
        method: 'GET',
        path: '/stream/chunks',
        headers: {...?(options?.mergeHeaders(null)), ...extra},
        requestBytes: Uint8List(0),
        options: options,
      ),
      models.ChatMessage.fromJson,
    );
  }

  /// Frames of `stream_chunks` as a typed stream. Cancelling the subscription
  /// cancels the request.
  Stream<models.ChatMessage> streamChunksStream({AxiomCallOptions? options}) {
    final response = _runtime.callStream(
      namespace: _namespace,
      endpointId: 3842853571,
      method: 'GET',
      path: '/stream/chunks',
      headers: options?.mergeHeaders(null),
      requestBytes: Uint8List(0),
      options: options,
    );
    return _frames(response, _runtime, models.ChatMessage.fromJson);
  }

  /// `GET /stream/sse` (sse).
  AxiomQuery<models.ChatMessage> streamSse({AxiomCallOptions? options}) {
    return _streamQuery<models.ChatMessage>(
      '${_namespace}_2163966778_stream_${jsonEncode(<String, dynamic>{})}',
      _runtime,
      (extra) => _runtime.callStream(
        namespace: _namespace,
        endpointId: 2163966778,
        method: 'GET',
        path: '/stream/sse',
        headers: {...?(options?.mergeHeaders(null)), ...extra},
        requestBytes: Uint8List(0),
        options: options,
      ),
      models.ChatMessage.fromJson,
    );
  }

  /// Frames of `stream_sse` as a typed stream. Cancelling the subscription
  /// cancels the request.
  Stream<models.ChatMessage> streamSseStream({AxiomCallOptions? options}) {
    final response = _runtime.callStream(
      namespace: _namespace,
      endpointId: 2163966778,
      method: 'GET',
      path: '/stream/sse',
      headers: options?.mergeHeaders(null),
      requestBytes: Uint8List(0),
      options: options,
    );
    return _frames(response, _runtime, models.ChatMessage.fromJson);
  }

  /// `WS /ws/chat` (websocket).
  AxiomQuery<models.ChatMessage> websocketEndpoint({
    required String text,
    AxiomCallOptions? options,
  }) {
    return _runtime.send<models.ChatMessage>(
      namespace: _namespace,
      endpointId: 3385426738,
      method: 'WS',
      path: '/ws/chat',
      headers: options?.mergeHeaders(null),
      body: jsonEncode(text),
      args: <String, dynamic>{'text': text},
      decoder: models.ChatMessage.fromJson,
      options: options,
    );
  }

  /// Typed WebSocket channel for `websocket_endpoint`: send [String], receive [models.ChatMessage].
  AxiomChannel<models.ChatMessage, String> websocketEndpointChannel({
    AxiomReconnectPolicy reconnect = AxiomReconnectPolicy.auto,
    AxiomCallOptions? options,
  }) {
    return _runtime.openChannel<models.ChatMessage, String>(
      namespace: _namespace,
      endpointId: 3385426738,
      method: 'WS',
      path: '/ws/chat',
      headers: options?.mergeHeaders(null),
      decoder: models.ChatMessage.fromJson,
      reconnect: reconnect,
      options: options,
    );
  }

  /// Refetches the active queries of every endpoint with [identity].
  void invalidateIdentity(String identity) {
    final ids = cacheIdentities[identity];
    if (ids == null) return;
    _invalidateEndpoints(_runtime, _namespace, ids);
  }
}

/// Namespace-level runtime controls for `stream`.
class StreamModuleAxiomNamespace {
  StreamModuleAxiomNamespace._(this._runtime, this._namespace);

  final AxiomRuntime _runtime;
  final String _namespace;

  void setAuthToken(String methodName, String token) {
    _runtime.setAuthToken(
      namespace: _namespace,
      methodName: methodName,
      token: token,
    );
  }

  void clearAuthToken(String methodName) {
    _runtime.clearAuthToken(namespace: _namespace, methodName: methodName);
  }

  /// Sets [token] for every auth method of this namespace.
  void setNamespaceToken(String token) {
    _runtime.setNamespaceAuthToken(namespace: _namespace, token: token);
  }

  void clearNamespaceToken() {
    _runtime.clearNamespaceAuthToken(namespace: _namespace);
  }

  /// Marks every cached query of this namespace stale and refetches.
  void invalidateAll() {
    _runtime.invalidate(namespace: _namespace);
  }
}

/// Start-up for axiom_flutter versions whose initialize() is not
/// implemented yet: init + loadContract per namespace.
Future<AxiomInitResult> _legacyInit(
  AxiomRuntime runtime,
  AxiomConfig cfg,
  AxiomAssetLoader? assetLoader,
) async {
  final load =
      assetLoader ??
      (String path) async => (await rootBundle.load(path)).buffer.asUint8List();
  await runtime.init(cfg.dbPath);
  final contracts = <String, AxiomContractLoadResult>{};
  for (final entry in cfg.contracts.entries) {
    final baseUrl = cfg.resolveBaseUrl(entry.key);
    runtime.loadContract(
      namespace: entry.key,
      baseUrl: baseUrl,
      contractBytes: await load(entry.value.assetPath),
      signature: entry.value.signature,
      publicKey: entry.value.publicKey,
    );
    contracts[entry.key] = AxiomContractLoadResult(
      namespace: entry.key,
      baseUrl: baseUrl,
      status: entry.value.signature == null ? -1 : 0,
      trust: entry.value.signature == null
          ? AxiomContractTrust.unsigned
          : AxiomContractTrust.signed,
    );
  }
  return AxiomInitResult(ok: true, contracts: contracts);
}

/// Refetches active queries of [endpointIds] after a mutation (the runtime
/// already dropped their cached responses).
void _invalidateEndpoints(
  AxiomRuntime runtime,
  String namespace,
  List<int> endpointIds,
) {
  for (final id in endpointIds) {
    try {
      runtime.invalidate(namespace: namespace, endpointId: id);
    } on UnimplementedError {
      return;
    }
  }
}

/// An [AxiomQuery] over a streaming endpoint: one success state per frame.
AxiomQuery<T> _streamQuery<T>(
  String key,
  AxiomRuntime runtime,
  AxiomStreamResponse Function(Map<String, String> extra) open,
  T Function(Object?) decode,
) {
  return AxiomQuery<T>(key, (extra) {
    final response = open(extra);
    final states = response.stream.expand<AxiomState<T>>((state) {
      final error = state.error;
      if (error != null) return [AxiomState<T>.error(error)];
      final data = state.data;
      if (data == null || data.isEmpty) {
        return state.isLoading ? [AxiomState<T>.loading()] : const [];
      }
      try {
        return [
          for (final frame in _splitFrames(utf8.decode(data)))
            AxiomState<T>.success(
              decode(frame),
              state.source,
              isStreaming: true,
            ),
        ];
      } on FormatException catch (e) {
        return [
          AxiomState<T>.error(
            AxiomError(
              stage: ErrorStage.deserialize,
              category: ErrorCategory.serialization,
              code: const CodecError(),
              message: e.message,
              retryable: false,
            ),
          ),
        ];
      }
    }).asBroadcastStream();
    return AxiomActiveStream<T>(response.requestId, states);
  }, runtime: runtime);
}

/// Decodes stream chunks (JSON, NDJSON or SSE `data:` lines) into frames.
Stream<T> _frames<T>(
  AxiomStreamResponse response,
  AxiomRuntime runtime,
  T Function(Object?) decode,
) async* {
  var finished = false;
  try {
    await for (final state in response.stream) {
      final error = state.error;
      if (error != null) {
        finished = true;
        if (error.isCancelled) return;
        throw error;
      }
      final data = state.data;
      if (data != null && data.isNotEmpty) {
        for (final frame in _splitFrames(utf8.decode(data))) {
          yield decode(frame);
        }
      }
    }
    finished = true;
  } finally {
    if (!finished) {
      try {
        runtime.cancel(response.requestId);
      } on UnimplementedError {
        // Runtime without cancel support.
      }
    }
  }
}

List<Object?> _splitFrames(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  if (!trimmed.startsWith('data:') &&
      !trimmed.startsWith('event:') &&
      !trimmed.startsWith('id:') &&
      !trimmed.startsWith(':')) {
    try {
      return [jsonDecode(trimmed)];
    } on FormatException {
      return [
        for (final line in trimmed.split('\n'))
          if (line.trim().isNotEmpty) jsonDecode(line),
      ];
    }
  }
  final frames = <Object?>[];
  final data = <String>[];
  for (final line in '$trimmed\n\n'.split('\n')) {
    if (line.startsWith('data:')) {
      data.add(line.substring(5).trimLeft());
    } else if (line.trim().isEmpty && data.isNotEmpty) {
      frames.add(jsonDecode(data.join('\n')));
      data.clear();
    }
  }
  return frames;
}
