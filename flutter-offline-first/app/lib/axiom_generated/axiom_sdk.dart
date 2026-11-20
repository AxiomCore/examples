// GENERATED CODE - DO NOT EDIT.
// axiom_flutter_generator 0.150.0
// feed: examples.offline_feed 1.0.0 variant default schema c082034dcdb7

import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models.dart' as models;

/// Contract configuration written by `axiom pull`.
abstract final class AxiomDefaultConfig {
  static const AxiomConfig config = AxiomConfig(
    contracts: {
      'feed': AxiomContractConfig(
        // Neither the contract nor the pull config names a base URL;
        // override with AxiomEnvironment or --dart-define=AXIOM_BASE_URL.
        baseUrl: 'http://localhost:8000',
        assetPath: 'assets/axiom/feed.axiom',
      ),
    },
  );

  /// sha256 of each contract asset at generation time.
  static const Map<String, String> contractSha256 = {
    'feed': '68d9cf5c83647234b1a8a78e84b44a97c650e77e8f19f052f3b65a493c301dfc',
  };
}

/// Entry point of the generated client.
class AxiomSdk {
  /// Wraps an already initialized [runtime] (tests, custom start-up).
  AxiomSdk.fromRuntime(
    this.runtime, [
    this.initResult = const AxiomInitResult(ok: true),
  ]) : feed = FeedModule._(runtime, 'feed');

  final AxiomRuntime runtime;

  /// Outcome of runtime start-up and contract loading.
  final AxiomInitResult initResult;

  /// Endpoints of the `feed` contract.
  final FeedModule feed;

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

/// Client for the `feed` contract (examples.offline_feed 1.0.0).
class FeedModule {
  FeedModule._(this._runtime, this._namespace)
    : axiom = FeedModuleAxiomNamespace._(_runtime, _namespace);

  /// Binds this client to another namespace of [runtime], for example the same
  /// contract loaded a second time with a different base URL.
  FeedModule(AxiomRuntime runtime, String namespace)
    : this._(runtime, namespace);

  final AxiomRuntime _runtime;
  final String _namespace;

  /// Auth tokens and cache control for this namespace.
  final FeedModuleAxiomNamespace axiom;

  /// Endpoint ids by contract endpoint name.
  static const Map<String, int> endpointIds = {
    'health': 4266132609,
    'latestFeed': 325731740,
    'pinnedFeed': 3302792537,
  };

  /// Endpoint ids by contract cache identity.
  static const Map<String, List<int>> cacheIdentities = {};

  /// Auth method names declared by the contract.
  static const List<String> authMethods = [];

  /// `GET /health`.
  AxiomQuery<models.Health> health({AxiomCallOptions? options}) {
    return _runtime.send<models.Health>(
      namespace: _namespace,
      endpointId: 4266132609,
      method: 'GET',
      path: '/health',
      headers: options?.mergeHeaders(null),
      args: <String, dynamic>{},
      decoder: models.Health.fromJson,
      options: options,
    );
  }

  /// `GET /feed/latest`.
  ///
  /// Cache: `stale_while_revalidate`, ttl 30s. Pass `options: AxiomCallOptions(cacheMode: AxiomCacheMode.refresh)` to bypass it.
  AxiomQuery<models.Feed> latestFeed({AxiomCallOptions? options}) {
    return _runtime.send<models.Feed>(
      namespace: _namespace,
      endpointId: 325731740,
      method: 'GET',
      path: '/feed/latest',
      headers: options?.mergeHeaders(null),
      args: <String, dynamic>{},
      decoder: models.Feed.fromJson,
      options: options,
    );
  }

  /// `GET /feed/pinned`.
  ///
  /// Cache: `cache_first`, ttl 3600s. Pass `options: AxiomCallOptions(cacheMode: AxiomCacheMode.refresh)` to bypass it.
  AxiomQuery<models.Feed> pinnedFeed({AxiomCallOptions? options}) {
    return _runtime.send<models.Feed>(
      namespace: _namespace,
      endpointId: 3302792537,
      method: 'GET',
      path: '/feed/pinned',
      headers: options?.mergeHeaders(null),
      args: <String, dynamic>{},
      decoder: models.Feed.fromJson,
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

/// Namespace-level runtime controls for `feed`.
class FeedModuleAxiomNamespace {
  FeedModuleAxiomNamespace._(this._runtime, this._namespace);

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
