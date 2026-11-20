// The smallest axiom_flutter app: one generated query, no Material.
import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart';

const _url = String.fromEnvironment('AXIOM_BASE_URL');

String backendUrl() => _url.isNotEmpty
    ? _url
    : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:8080' // the Android emulator's view of your computer
    : 'http://127.0.0.1:8080';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sdk = await AxiomSdk.create(
    baseUrlOverrides: {'minimal': backendUrl()},
  );
  final hello = sdk.minimal.hello();
  if (const bool.fromEnvironment('AXIOM_EXAMPLE_AUTORUN')) {
    hello.stream.firstWhere((s) => s.hasData || s.hasError).then((s) {
      debugPrint(
        'AXIOM_EXAMPLE hello ${s.hasData ? 'PASS ${s.data!.message}' : 'FAIL ${s.error}'}',
      );
      debugPrint('AXIOM_EXAMPLE DONE');
    });
  }
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: AxiomBuilder<Hello, Hello>(
          query: hello,
          loading: (_) => const Text('Loading...'),
          error: (_, e) => Text(e.message),
          builder: (_, _, data) => Text(data.message),
        ),
      ),
    ),
  );
}
