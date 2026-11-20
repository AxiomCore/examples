// Sign-in, session restore and sign-out with axiom_flutter_auth.
//
// The access token goes only to the `api` namespace (our own backend); the
// guarded GET /me answers 401 without it.
import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:axiom_flutter_auth/axiom_flutter_auth.dart';
import 'package:flutter/material.dart';

import 'autorun.dart';
import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart' as models;
import 'config.dart';

late final AxiomSdk sdk;
late final AxiomAuth auth;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sdk = await AxiomSdk.create(baseUrlOverrides: {'api': apiUrl()});
  auth = createAxiomAuth(
    AxiomAuthOptions(
      issuer: issuerUrl(),
      // Keychain / Keystore on mobile and macOS, sessionStorage on the web:
      // the session survives an app restart (a page reload on the web).
      storage: platformStorage(),
    ),
  );
  // Only the listed namespaces get the user's token.
  AxiomAuthBinding.attach(
    auth,
    runtime: sdk.runtime,
    namespaces: const ['api'],
  );
  if (autorunEnabled) {
    await autorun(sdk, auth);
  } else {
    await auth.restore();
  }
  runApp(AxiomAuthLifecycle(auth: auth, child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Axiom auth example',
    home: AxiomAuthBuilder(
      auth: auth,
      loading: (_, _) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      signedIn: (_, session) => const HomePage(),
      signedOut: (_, _) => const SignInPage(),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signed in')),
      body: AxiomBuilder<models.Me, models.Me>(
        query: sdk.api.me(),
        loading: (_) => const Center(child: CircularProgressIndicator()),
        error: (_, error) => Center(child: Text('GET /me: ${error.message}')),
        builder: (_, _, me) => ListTile(
          title: Text(me.message),
          subtitle: Text('subject ${me.subject}'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => auth.signOut(),
        label: const Text('Sign out'),
      ),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  String? challenge;
  String? message;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => message = null);
    try {
      await action();
    } on AxiomAuthError catch (e) {
      setState(() => message = 'Failed: ${e.code}');
    }
  }

  Future<void> _signUp() async {
    final result = await auth.signUp(email.text, password.text);
    setState(() {
      challenge = result.challenge;
      message = result.status == 'verification_sent'
          ? 'Code sent. The emulator shows it at /local/mail.'
          : result.status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password (8 characters or more)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                _run(() => auth.signInWithPassword(email.text, password.text)),
            child: const Text('Sign in'),
          ),
          OutlinedButton(
            onPressed: () => _run(_signUp),
            child: const Text('Create account'),
          ),
          if (challenge != null) ...[
            TextField(
              controller: code,
              decoration: const InputDecoration(labelText: 'Code from mail'),
            ),
            FilledButton(
              onPressed: () =>
                  _run(() => auth.verifySignUp(challenge!, code.text)),
              child: const Text('Verify and sign in'),
            ),
          ],
          if (message != null) Text(message!),
        ],
      ),
    );
  }
}
