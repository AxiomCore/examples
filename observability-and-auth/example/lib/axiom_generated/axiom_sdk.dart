// GENERATED CODE - DO NOT EDIT.
// axiom_flutter_generator 0.147.5
// auth_obs_test: auth-obs-test 1.0.0 variant default schema a7dee42be107

import 'dart:typed_data';

import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models.dart' as models;

/// Contract configuration written by `axiom pull`.
abstract final class AxiomDefaultConfig {
  static const AxiomConfig config = AxiomConfig(
    contracts: {
      'auth_obs_test': AxiomContractConfig(
        baseUrl: 'http://127.0.0.1:8000',
        assetPath: 'assets/axiom/auth_obs_test.axiom',
      ),
    },
  );

  /// sha256 of each contract asset at generation time.
  static const Map<String, String> contractSha256 = {
    'auth_obs_test':
        'dc4509f45aa4565fe4159deb20ff4b346bf193df28cdf1af48b8a704afb96064',
  };
}

/// Entry point of the generated client.
class AxiomSdk {
  /// Wraps an already initialized [runtime] (tests, custom start-up).
  AxiomSdk.fromRuntime(
    this.runtime, [
    this.initResult = const AxiomInitResult(ok: true),
  ]) : authObsTest = AuthObsTestModule._(runtime, 'auth_obs_test');

  final AxiomRuntime runtime;

  /// Outcome of runtime start-up and contract loading.
  final AxiomInitResult initResult;

  /// Endpoints of the `auth_obs_test` contract.
  final AuthObsTestModule authObsTest;

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

/// Client for the `auth_obs_test` contract (auth-obs-test 1.0.0).
class AuthObsTestModule {
  AuthObsTestModule._(this._runtime, this._namespace)
    : axiom = AuthObsTestModuleAxiomNamespace._(_runtime, _namespace);

  final AxiomRuntime _runtime;
  final String _namespace;

  /// Auth tokens and cache control for this namespace.
  final AuthObsTestModuleAxiomNamespace axiom;

  /// Endpoint ids by contract endpoint name.
  static const Map<String, int> endpointIds = {
    'login': 4166688716,
    'protected_api_key_header': 2,
    'protected_api_key_query': 3,
    'protected_jwt': 1,
    'protected_multi': 4,
  };

  /// Endpoint ids by contract cache identity.
  static const Map<String, List<int>> cacheIdentities = {};

  /// Auth method names declared by the contract.
  static const List<String> authMethods = [
    'Authorization',
    'api_key',
    'x-api-key',
  ];

  /// `POST /login`.
  AxiomQuery<Object?> login({
    String? idempotencyKey,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{
      if (idempotencyKey case final k?) 'Idempotency-Key': k,
    };
    return _runtime.sendMutation<Object?>(
      namespace: _namespace,
      endpointId: 4166688716,
      method: 'POST',
      path: '/login',
      headers: options?.mergeHeaders(headers) ?? headers,
      args: <String, dynamic>{},
      decoder: models.AxiomGeneratedCodec.asJson,
      options: options,
    );
  }

  /// `GET /protected/api-key-header`.
  AxiomQuery<Object?> protectedApiKeyHeader({
    String? xApiKey,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{if (xApiKey case final v?) 'x_api_key': v};
    return _runtime.send<Object?>(
      namespace: _namespace,
      endpointId: 2,
      method: 'GET',
      path: '/protected/api-key-header',
      headers: options?.mergeHeaders(headers) ?? headers,
      args: <String, dynamic>{if (xApiKey case final v?) 'x_api_key': v},
      decoder: models.AxiomGeneratedCodec.asJson,
      options: options,
    );
  }

  /// `GET /protected/api-key-query`.
  AxiomQuery<Object?> protectedApiKeyQuery({
    String? apiKey,
    AxiomCallOptions? options,
  }) {
    return _runtime.send<Object?>(
      namespace: _namespace,
      endpointId: 3,
      method: 'GET',
      path: '/protected/api-key-query',
      headers: options?.mergeHeaders(null),
      queryParams: {if (apiKey case final v?) 'api_key': v},
      args: <String, dynamic>{if (apiKey case final v?) 'api_key': v},
      decoder: models.AxiomGeneratedCodec.asJson,
      options: options,
    );
  }

  /// `GET /protected/jwt`.
  AxiomQuery<Object?> protectedJwt({
    String? authorization,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{
      if (authorization case final v?) 'authorization': v,
    };
    return _runtime.send<Object?>(
      namespace: _namespace,
      endpointId: 1,
      method: 'GET',
      path: '/protected/jwt',
      headers: options?.mergeHeaders(headers) ?? headers,
      args: <String, dynamic>{
        if (authorization case final v?) 'authorization': v,
      },
      decoder: models.AxiomGeneratedCodec.asJson,
      options: options,
    );
  }

  /// `GET /protected/multi`.
  AxiomQuery<Object?> protectedMulti({
    String? authorization,
    String? xApiKey,
    AxiomCallOptions? options,
  }) {
    final headers = <String, String>{
      if (authorization case final v?) 'authorization': v,
      if (xApiKey case final v?) 'x_api_key': v,
    };
    return _runtime.send<Object?>(
      namespace: _namespace,
      endpointId: 4,
      method: 'GET',
      path: '/protected/multi',
      headers: options?.mergeHeaders(headers) ?? headers,
      args: <String, dynamic>{
        if (authorization case final v?) 'authorization': v,
        if (xApiKey case final v?) 'x_api_key': v,
      },
      decoder: models.AxiomGeneratedCodec.asJson,
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

/// Namespace-level runtime controls for `auth_obs_test`.
class AuthObsTestModuleAxiomNamespace {
  AuthObsTestModuleAxiomNamespace._(this._runtime, this._namespace);

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
