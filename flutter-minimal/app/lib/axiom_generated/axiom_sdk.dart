// GENERATED CODE - DO NOT EDIT.
// axiom_flutter_generator 0.150.0
// minimal: examples.minimal 1.0.0 variant default schema 976399147a30

import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models.dart' as models;

/// Contract configuration written by `axiom pull`.
abstract final class AxiomDefaultConfig {
  static const AxiomConfig config = AxiomConfig(
    contracts: {
      'minimal': AxiomContractConfig(
        // Neither the contract nor the pull config names a base URL;
        // override with AxiomEnvironment or --dart-define=AXIOM_BASE_URL.
        baseUrl: 'http://localhost:8000',
        assetPath: 'assets/axiom/minimal.axiom',
      ),
    },
  );

  /// sha256 of each contract asset at generation time.
  static const Map<String, String> contractSha256 = {
    'minimal':
        '5bd562cede08690164977779f1886e3464c932f75bf7ee42af8b9f5464a89742',
  };
}

/// Entry point of the generated client.
class AxiomSdk {
  /// Wraps an already initialized [runtime] (tests, custom start-up).
  AxiomSdk.fromRuntime(
    this.runtime, [
    this.initResult = const AxiomInitResult(ok: true),
  ]) : minimal = MinimalModule._(runtime, 'minimal');

  final AxiomRuntime runtime;

  /// Outcome of runtime start-up and contract loading.
  final AxiomInitResult initResult;

  /// Endpoints of the `minimal` contract.
  final MinimalModule minimal;

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

/// Client for the `minimal` contract (examples.minimal 1.0.0).
class MinimalModule {
  MinimalModule._(this._runtime, this._namespace)
    : axiom = MinimalModuleAxiomNamespace._(_runtime, _namespace);

  /// Binds this client to another namespace of [runtime], for example the same
  /// contract loaded a second time with a different base URL.
  MinimalModule(AxiomRuntime runtime, String namespace)
    : this._(runtime, namespace);

  final AxiomRuntime _runtime;
  final String _namespace;

  /// Auth tokens and cache control for this namespace.
  final MinimalModuleAxiomNamespace axiom;

  /// Endpoint ids by contract endpoint name.
  static const Map<String, int> endpointIds = {'hello': 3602747056};

  /// Endpoint ids by contract cache identity.
  static const Map<String, List<int>> cacheIdentities = {};

  /// Auth method names declared by the contract.
  static const List<String> authMethods = [];

  /// `GET /hello`.
  AxiomQuery<models.Hello> hello({AxiomCallOptions? options}) {
    return _runtime.send<models.Hello>(
      namespace: _namespace,
      endpointId: 3602747056,
      method: 'GET',
      path: '/hello',
      headers: options?.mergeHeaders(null),
      args: <String, dynamic>{},
      decoder: models.Hello.fromJson,
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

/// Namespace-level runtime controls for `minimal`.
class MinimalModuleAxiomNamespace {
  MinimalModuleAxiomNamespace._(this._runtime, this._namespace);

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
