// Headless smoke check for this example. Not part of the quickstart.
//
// It runs the same app as lib/main.dart, then calls both endpoints once and
// prints `AXIOM_EXAMPLE <step> PASS|FAIL` lines:
//
//   flutter run -d chrome --web-port 5000 -t tool/autorun_main.dart
//   flutter build web -t tool/autorun_main.dart \
//     --dart-define=AXIOM_BASE_URL=http://127.0.0.1:8080
import 'package:flutter/material.dart';
import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:talks_app/axiom_generated/axiom_sdk.dart';
import 'package:talks_app/main.dart' as app;

/// Waits for the first data or error state. Written with `then`: awaiting a
/// query stream inside an `async` function can crash in dart2js builds.
Future<T> result<T>(AxiomQuery<T> query) => query.stream
    .firstWhere((s) => s.hasData || s.hasError)
    .timeout(const Duration(seconds: 20))
    .then((s) => s.hasError ? throw s.error! : s.data as T);

Future<void> step(String name, Future<String> Function() body) async {
  try {
    debugPrint('AXIOM_EXAMPLE $name PASS ${await body()}');
  } catch (e) {
    debugPrint('AXIOM_EXAMPLE $name FAIL $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('AXIOM_BASE_URL');
  try {
    app.sdk = await AxiomSdk.create(
      baseUrlOverrides: {'talks': url.isEmpty ? app.backendUrl() : url},
    );
    debugPrint('AXIOM_EXAMPLE init PASS');
  } catch (e) {
    debugPrint('AXIOM_EXAMPLE init FAIL $e');
    debugPrint('AXIOM_EXAMPLE DONE');
    return;
  }
  runApp(const MaterialApp(home: app.TalksPage()));
  await step('listTalks', () async {
    final list = await result(app.sdk.talks.listTalks());
    final titles = list.talks.map((t) => '${t.title}/${t.speaker}').join(', ');
    if (list.talks.length != 2) throw StateError('expected 2 talks: $titles');
    return titles;
  });
  await step('createTalk', () async {
    final talk = await result(
      app.sdk.talks.createTalk(title: 'My new talk', speaker: 'You'),
    );
    if (talk.id != 't3') throw StateError('expected id t3, got ${talk.id}');
    return 'Created ${talk.id}';
  });
  debugPrint('AXIOM_EXAMPLE DONE');
}
