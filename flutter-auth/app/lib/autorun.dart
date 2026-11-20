// Headless smoke run: --dart-define=AXIOM_EXAMPLE_AUTORUN=true plus
// AXIOM_EXAMPLE_EMAIL / AXIOM_EXAMPLE_PASSWORD of an existing emulator user.
//
// First start: restore (nothing stored), GET /me is refused, sign in, GET /me
// answers. Then the app restarts (web: page reload) and must restore the
// session from storage, call GET /me, sign out, and see GET /me refused again.
import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:axiom_flutter_auth/axiom_flutter_auth.dart';
import 'package:flutter/foundation.dart';

import 'axiom_generated/axiom_sdk.dart';
import 'restart_stub.dart' if (dart.library.js_interop) 'restart_web.dart';

const autorunEnabled = bool.fromEnvironment('AXIOM_EXAMPLE_AUTORUN');
const _email = String.fromEnvironment('AXIOM_EXAMPLE_EMAIL');
const _password = String.fromEnvironment(
  'AXIOM_EXAMPLE_PASSWORD',
  defaultValue: 'correct horse battery',
);

void _log(String line) => debugPrint('AXIOM_EXAMPLE $line');

/// Waits for the first data or error state. Written with `then`: awaiting a
/// query stream inside an `async` function can crash in dart2js builds.
Future<T> result<T>(AxiomQuery<T> query) => query.stream
    .firstWhere((s) => s.hasData || s.hasError)
    .timeout(const Duration(seconds: 20))
    .then((s) => s.hasError ? throw s.error! : s.data as T);

Future<void> _step(String name, Future<String> Function() body) async {
  try {
    _log('$name PASS ${await body()}');
  } catch (e) {
    _log('$name FAIL $e');
  }
}

Future<String> _meRefused(AxiomSdk sdk) async {
  try {
    final me = await result(
      sdk.api.me(
        options: const AxiomCallOptions(cacheMode: AxiomCacheMode.refresh),
      ),
    );
    throw StateError('expected 401, got ${me.subject}');
  } on AxiomError catch (e) {
    final code = e.code;
    if (code is HttpStatus && code.code == 401) return '401';
    rethrow;
  }
}

Future<String> _meAnswers(AxiomSdk sdk) async {
  final me = await result(
    sdk.api.me(
      options: const AxiomCallOptions(cacheMode: AxiomCacheMode.refresh),
    ),
  );
  return me.subject;
}

Future<void> autorun(AxiomSdk sdk, AxiomAuth auth) async {
  final restored = await auth.restore();
  if (restored.status != AuthStatus.authenticated) {
    _log('restore-empty PASS ${restored.status.name}');
    await _step('me-signed-out', () => _meRefused(sdk));
    await _step('sign-in', () async {
      final s = await auth.signInWithPassword(_email, _password);
      return s.status.name;
    });
    await _step('me-signed-in', () => _meAnswers(sdk));
    _log('restart (reload) to test session restore');
    restartApp();
    return;
  }
  _log('restore PASS ${restored.status.name} ${restored.principal!.subject}');
  await _step('me-restored', () => _meAnswers(sdk));
  await _step('sign-out', () async {
    final s = await auth.signOut();
    return s.status.name;
  });
  await _step('me-after-sign-out', () => _meRefused(sdk));
  _log('DONE');
}
