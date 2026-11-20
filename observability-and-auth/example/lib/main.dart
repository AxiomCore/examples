import 'dart:async';

import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/material.dart';

import 'axiom_generated/axiom_sdk.dart';

late final AxiomSdk sdk;

/// Public fixture key accepted by `../test_server.py`. Not a secret.
const fixtureApiKey = 'development-only-api-key';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads assets/axiom/auth_obs_test.axiom. Default base URL
  // http://127.0.0.1:8000; override with --dart-define=AXIOM_BASE_URL=<url>.
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

  runApp(const MyApp());

  if (const bool.fromEnvironment('AXIOM_EXAMPLE_AUTORUN')) {
    await _smoke();
  }
}

/// Waits for the first data or error state of [query].
Future<AxiomState<Object?>> settle(AxiomQuery<Object?> query) => query.stream
    .firstWhere((s) => s.hasData || s.hasError)
    .timeout(const Duration(seconds: 20));

/// Calls `/login` (a synthetic identity) and stores the JWT for the
/// `Authorization` auth method of this contract.
Future<String> login() async {
  final state = await settle(sdk.authObsTest.login());
  if (state.hasError) throw state.error!;
  final token = (state.data as Map?)?['token'] as String?;
  if (token == null) throw StateError('login returned no token');
  sdk.authObsTest.axiom.setAuthToken('Authorization', token);
  return 'token stored';
}

Future<void> _smoke() async {
  Future<void> run(String name, Future<String> Function() body) async {
    try {
      debugPrint('AXIOM_EXAMPLE $name PASS ${await body()}');
    } catch (e) {
      debugPrint('AXIOM_EXAMPLE $name FAIL $e');
    }
  }

  Future<String> ok(AxiomQuery<Object?> q) async {
    final s = await settle(q);
    if (s.hasError) throw s.error!;
    return '${s.data}';
  }

  await run('login', login);
  await run('jwt', () => ok(sdk.authObsTest.protectedJwt()));
  sdk.authObsTest.axiom.setAuthToken('x-api-key', fixtureApiKey);
  await run(
    'api-key-header',
    () => ok(sdk.authObsTest.protectedApiKeyHeader()),
  );
  sdk.authObsTest.axiom.setAuthToken('api_key', fixtureApiKey);
  await run('api-key-query', () => ok(sdk.authObsTest.protectedApiKeyQuery()));
  await run('multi', () => ok(sdk.authObsTest.protectedMulti()));
  debugPrint('AXIOM_EXAMPLE DONE');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AuthTesterScreen());
  }
}

class AuthTesterScreen extends StatefulWidget {
  const AuthTesterScreen({super.key});

  @override
  State<AuthTesterScreen> createState() => _AuthTesterScreenState();
}

class _AuthTesterScreenState extends State<AuthTesterScreen> {
  String log = 'Awaiting execution...';
  StreamSubscription<AxiomState<Object?>>? _sub;

  void _log(String message) => setState(() => log += '\n$message');

  void _start(String message) => setState(() => log = message);

  /// Shows every state of [query]: loading, data (network or cache), error.
  void _listenToQuery(AxiomQuery<Object?> query, String actionName) {
    _start('Executing...');
    _sub?.cancel();
    _sub = query.stream.listen((state) {
      if (state.isLoading) {
        _log('[$actionName] loading...');
      } else if (state.hasError) {
        _log('[$actionName] error: ${state.error?.message}');
      } else if (state.hasData) {
        final source = state.source == AxiomSource.cache ? 'cache' : 'network';
        _log('[$actionName] ok ($source): ${state.data}');
      }
    });
  }

  Future<void> _login() async {
    _start('Logging in...');
    try {
      _log('[Login] ${await login()} for the Authorization method');
    } catch (e) {
      _log('[Login] error: $e');
    }
  }

  void _setApiKey(String method) {
    sdk.authObsTest.axiom.setAuthToken(method, fixtureApiKey);
    _start('API key set for the "$method" auth method.');
  }

  Future<void> _logout() async {
    // Cancels in-flight calls, clears session cache and every stored token.
    await sdk.runtime.resetSession();
    _start('Session reset: tokens and session cache cleared.');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Widget _test(String label, AxiomQuery<Object?> Function() query) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade100),
      onPressed: () => _listenToQuery(query(), label),
      child: Text('Test: $label'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth tester')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: SingleChildScrollView(
                child: Text(
                  log,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: const Text('1. Log in and set JWT'),
            ),
            ElevatedButton(
              onPressed: () => _setApiKey('x-api-key'),
              child: const Text('2. Set API key (header)'),
            ),
            ElevatedButton(
              onPressed: () => _setApiKey('api_key'),
              child: const Text('3. Set API key (query)'),
            ),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Log out (reset session)'),
            ),
            const Divider(height: 32),
            _test('JWT with scope', () => sdk.authObsTest.protectedJwt()),
            _test(
              'API key header',
              () => sdk.authObsTest.protectedApiKeyHeader(),
            ),
            _test(
              'API key query',
              () => sdk.authObsTest.protectedApiKeyQuery(),
            ),
            _test('JWT or API key', () => sdk.authObsTest.protectedMulti()),
          ],
        ),
      ),
    );
  }
}
