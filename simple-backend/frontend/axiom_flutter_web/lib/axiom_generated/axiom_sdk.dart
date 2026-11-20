// GENERATED CODE - DO NOT EDIT.
// axiom_flutter_generator 0.147.5
// py-example: py-example v0.0.6 variant default schema adb9b0e14c48

import 'dart:convert';
import 'dart:typed_data';

import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models.dart' as models;

/// Contract configuration written by `axiom pull`.
abstract final class AxiomDefaultConfig {
  static const AxiomConfig config = AxiomConfig(
    contracts: {
      'py-example': AxiomContractConfig(
        baseUrl: 'http://127.0.0.1:8000',
        assetPath: 'assets/axiom/py-example.axiom',
      ),
    },
  );

  /// sha256 of each contract asset at generation time.
  static const Map<String, String> contractSha256 = {
    'py-example':
        '2b1eb7b5dcf8728366806707ebabe30ed9578e80b401522946708056ed34bb7e',
  };
}

/// Entry point of the generated client.
class AxiomSdk {
  /// Wraps an already initialized [runtime] (tests, custom start-up).
  AxiomSdk.fromRuntime(
    this.runtime, [
    this.initResult = const AxiomInitResult(ok: true),
  ]) : pyExample = PyExampleModule._(runtime, 'py-example');

  final AxiomRuntime runtime;

  /// Outcome of runtime start-up and contract loading.
  final AxiomInitResult initResult;

  /// Endpoints of the `py-example` contract.
  final PyExampleModule pyExample;

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

/// Client for the `py-example` contract (py-example v0.0.6).
class PyExampleModule {
  PyExampleModule._(this._runtime, this._namespace)
    : axiom = PyExampleModuleAxiomNamespace._(_runtime, _namespace);

  final AxiomRuntime _runtime;
  final String _namespace;

  /// Auth tokens and cache control for this namespace.
  final PyExampleModuleAxiomNamespace axiom;

  /// Endpoint ids by contract endpoint name.
  static const Map<String, int> endpointIds = {
    'create_item': 2,
    'delete_item': 5,
    'get_item': 4,
    'list_items': 3,
    'list_users': 7,
    'login': 1,
    'register': 9,
    'send_email': 6,
    'websocket_endpoint': 8,
  };

  /// Endpoint ids by contract cache identity.
  static const Map<String, List<int>> cacheIdentities = {};

  /// Auth method names declared by the contract.
  static const List<String> authMethods = ['Authorization'];

  /// `POST /items`.
  AxiomQuery<models.Item> createItem({
    required models.ItemCreate item,
    String? idempotencyKey,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{
      if (idempotencyKey case final k?) 'Idempotency-Key': k,
    };
    return _runtime.sendMutation<models.Item>(
      namespace: _namespace,
      endpointId: 2,
      method: 'POST',
      path: '/items',
      headers: options?.mergeHeaders(headers) ?? headers,
      body: jsonEncode(item.toJson()),
      args: <String, dynamic>{'item': item.toJson()},
      decoder: models.Item.fromJson,
      options: options,
    );
  }

  /// `DELETE /items/{item_id}`.
  AxiomQuery<Object?> deleteItem({
    required String itemId,
    String? idempotencyKey,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{
      if (idempotencyKey case final k?) 'Idempotency-Key': k,
    };
    return _runtime.sendMutation<Object?>(
      namespace: _namespace,
      endpointId: 5,
      method: 'DELETE',
      path: '/items/{item_id}',
      headers: options?.mergeHeaders(headers) ?? headers,
      pathParams: {'item_id': Uri.encodeComponent(itemId)},
      args: <String, dynamic>{'item_id': itemId},
      decoder: models.AxiomGeneratedCodec.asJson,
      options: options,
    );
  }

  /// `GET /items/{item_id}`.
  AxiomQuery<models.Item> getItem({
    required String itemId,
    AxiomCallOptions? options,
  }) {
    return _runtime.send<models.Item>(
      namespace: _namespace,
      endpointId: 4,
      method: 'GET',
      path: '/items/{item_id}',
      headers: options?.mergeHeaders(null),
      pathParams: {'item_id': Uri.encodeComponent(itemId)},
      args: <String, dynamic>{'item_id': itemId},
      decoder: models.Item.fromJson,
      options: options,
    );
  }

  /// `GET /items`.
  AxiomQuery<List<models.Item>> listItems({
    int? skip,
    int? limit,
    String? search,
    AxiomCallOptions? options,
  }) {
    return _runtime.send<List<models.Item>>(
      namespace: _namespace,
      endpointId: 3,
      method: 'GET',
      path: '/items',
      headers: options?.mergeHeaders(null),
      queryParams: {
        if (skip case final v?) 'skip': v.toString(),
        if (limit case final v?) 'limit': v.toString(),
        if (search case final v?) 'search': v,
      },
      args: <String, dynamic>{
        if (skip case final v?) 'skip': v,
        if (limit case final v?) 'limit': v,
        if (search case final v?) 'search': v,
      },
      decoder: (json) =>
          models.AxiomGeneratedCodec.asList(json, models.Item.fromJson),
      options: options,
    );
  }

  /// `GET /admin/users`.
  AxiomQuery<Object?> listUsers({AxiomCallOptions? options}) {
    return _runtime.send<Object?>(
      namespace: _namespace,
      endpointId: 7,
      method: 'GET',
      path: '/admin/users',
      headers: options?.mergeHeaders(null),
      args: <String, dynamic>{},
      decoder: models.AxiomGeneratedCodec.asJson,
      options: options,
    );
  }

  /// `POST /login`.
  AxiomQuery<models.Token> login({
    String? idempotencyKey,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{
      if (idempotencyKey case final k?) 'Idempotency-Key': k,
    };
    return _runtime.sendMutation<models.Token>(
      namespace: _namespace,
      endpointId: 1,
      method: 'POST',
      path: '/login',
      headers: options?.mergeHeaders(headers) ?? headers,
      args: <String, dynamic>{},
      decoder: models.Token.fromJson,
      options: options,
    );
  }

  /// `POST /register`.
  AxiomQuery<models.User> register({
    required models.UserCreate user,
    String? idempotencyKey,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{
      if (idempotencyKey case final k?) 'Idempotency-Key': k,
    };
    return _runtime.sendMutation<models.User>(
      namespace: _namespace,
      endpointId: 9,
      method: 'POST',
      path: '/register',
      headers: options?.mergeHeaders(headers) ?? headers,
      body: jsonEncode(user.toJson()),
      args: <String, dynamic>{'user': user.toJson()},
      decoder: models.User.fromJson,
      options: options,
    );
  }

  /// `POST /send-email`.
  AxiomQuery<Object?> sendEmail({
    required Object? backgroundTasks,
    String? idempotencyKey,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{
      if (idempotencyKey case final k?) 'Idempotency-Key': k,
    };
    return _runtime.sendMutation<Object?>(
      namespace: _namespace,
      endpointId: 6,
      method: 'POST',
      path: '/send-email',
      headers: options?.mergeHeaders(headers) ?? headers,
      queryParams: {'background_tasks': jsonEncode(backgroundTasks)},
      args: <String, dynamic>{'background_tasks': backgroundTasks},
      decoder: models.AxiomGeneratedCodec.asJson,
      options: options,
    );
  }

  /// `WS /ws`.
  AxiomQuery<void> websocketEndpoint({AxiomCallOptions? options}) {
    return _runtime.send<void>(
      namespace: _namespace,
      endpointId: 8,
      method: 'WS',
      path: '/ws',
      headers: options?.mergeHeaders(null),
      args: <String, dynamic>{},
      decoder: models.AxiomGeneratedCodec.asVoid,
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

/// Namespace-level runtime controls for `py-example`.
class PyExampleModuleAxiomNamespace {
  PyExampleModuleAxiomNamespace._(this._runtime, this._namespace);

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
