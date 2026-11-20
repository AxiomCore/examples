import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/material.dart';

import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart';

late final AxiomSdk sdk;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads assets/axiom/py-example.axiom. Default base URL
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

  runApp(const ItemsApp());

  if (const bool.fromEnvironment('AXIOM_EXAMPLE_AUTORUN')) {
    await _smoke();
  }
}

/// Waits for the first data or error state and returns the data.
///
/// Written with `then` rather than `async`/`await`: with axiom_flutter
/// 0.147.5 on web (dart2js), awaiting a query stream inside an `async`
/// function can crash in release builds.
Future<T> result<T>(AxiomQuery<T> query) => query.stream
    .firstWhere((s) => s.hasData || s.hasError)
    .timeout(const Duration(seconds: 20))
    .then((s) => s.hasError ? throw s.error! : s.data as T);

/// `POST /login` takes an OAuth2 password form. The contract does not describe
/// form fields, so the form body is passed to the runtime directly; the
/// response is decoded with the generated `Token` model.
AxiomQuery<Token> login(String email, String password) {
  return sdk.runtime.sendMutation<Token>(
    namespace: 'py-example',
    endpointId: PyExampleModule.endpointIds['login']!,
    method: 'POST',
    path: '/login',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: Uri(queryParameters: {'username': email, 'password': password}).query,
    decoder: Token.fromJson,
  );
}

Future<void> _smoke() async {
  Future<Object?> run(String name, Future<Object?> Function() body) async {
    try {
      final Object? v = await body();
      debugPrint('AXIOM_EXAMPLE $name PASS $v');
      return v;
    } catch (e) {
      debugPrint('AXIOM_EXAMPLE $name FAIL $e');
      return null;
    }
  }

  final email = 'smoke-${DateTime.now().millisecondsSinceEpoch}@example.com';
  await run('register', () async {
    final user = await result(
      sdk.pyExample.register(
        user: UserCreate(email: email, password: 'smoke-pass'),
      ),
    );
    return user.email;
  });
  await run('login', () async {
    final token = await result(login(email, 'smoke-pass'));
    sdk.pyExample.axiom.setAuthToken('Authorization', token.accessToken);
    return 'token stored';
  });
  final item = await run('create', () async {
    return result<Item>(
      sdk.pyExample.createItem(
        item: const ItemCreate(title: 'Smoke item', description: 'hello'),
      ),
    );
  });
  await run('list', () async {
    final items = await result(sdk.pyExample.listItems(limit: 20));
    return '${items.length} items';
  });
  if (item is Item) {
    await run(
      'get',
      () async => (await result(sdk.pyExample.getItem(itemId: item.id))).title,
    );
    await run(
      'delete',
      () async => result(sdk.pyExample.deleteItem(itemId: item.id)),
    );
  }
  debugPrint('AXIOM_EXAMPLE DONE');
}

class ItemsApp extends StatelessWidget {
  const ItemsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Axiom simple backend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ItemsPage(),
    );
  }
}

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  bool signedIn = false;
  Item? createdItem;
  String status = '';

  final emailController = TextEditingController(text: 'test@example.com');
  final passwordController = TextEditingController(text: '123456');
  final titleController = TextEditingController(text: 'My item');

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    titleController.dispose();
    super.dispose();
  }

  Future<void> _do(String label, Future<String> Function() action) async {
    try {
      final message = await action();
      setState(() => status = '$label: $message');
    } on AxiomError catch (e) {
      setState(() => status = '$label failed: ${e.message}');
    } catch (e) {
      setState(() => status = '$label failed: $e');
    }
  }

  Future<String> _register() async {
    final user = await result(
      sdk.pyExample.register(
        user: UserCreate(
          email: emailController.text,
          password: passwordController.text,
        ),
      ),
    );
    return 'registered ${user.email}';
  }

  Future<String> _login() async {
    final token = await result(
      login(emailController.text, passwordController.text),
    );
    // The runtime attaches the token to every endpoint that declares the
    // `Authorization` auth method.
    sdk.pyExample.axiom.setAuthToken('Authorization', token.accessToken);
    setState(() => signedIn = true);
    return 'signed in';
  }

  Future<String> _create() async {
    final item = await result(
      sdk.pyExample.createItem(
        item: ItemCreate(title: titleController.text, description: 'hello'),
      ),
    );
    setState(() => createdItem = item);
    sdk.pyExample.listItems().refresh();
    return 'created ${item.id}';
  }

  Future<String> _delete() async {
    await result(sdk.pyExample.deleteItem(itemId: createdItem!.id));
    setState(() => createdItem = null);
    sdk.pyExample.listItems().refresh();
    return 'deleted';
  }

  Future<String> _logout() async {
    await sdk.runtime.resetSession();
    setState(() {
      signedIn = false;
      createdItem = null;
    });
    return 'session reset';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Axiom simple backend')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _do('Register', _register),
                child: const Text('Register'),
              ),
              ElevatedButton(
                onPressed: () => _do('Login', _login),
                child: const Text('Login'),
              ),
              ElevatedButton(
                onPressed: signedIn ? () => _do('Logout', _logout) : null,
                child: const Text('Logout'),
              ),
            ],
          ),
          const Divider(height: 32),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Item title'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: signedIn ? () => _do('Create', _create) : null,
                child: const Text('Create item'),
              ),
              ElevatedButton(
                onPressed: signedIn && createdItem != null
                    ? () => _do('Delete', _delete)
                    : null,
                child: const Text('Delete created item'),
              ),
            ],
          ),
          if (status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(status),
            ),
          if (createdItem != null)
            AxiomBuilder<Item, Item>(
              query: sdk.pyExample.getItem(itemId: createdItem!.id),
              builder: (context, state, _) => state.hasData
                  ? Text('Fetched by id: ${state.data!.title}')
                  : const SizedBox.shrink(),
            ),
          const Divider(height: 32),
          Text('Items', style: Theme.of(context).textTheme.titleMedium),
          AxiomBuilder<List<Item>, List<Item>>(
            query: sdk.pyExample.listItems(limit: 50),
            builder: (context, state, _) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.hasError) {
                return Text('Error: ${state.error?.message}');
              }
              final items = state.data ?? const <Item>[];
              if (items.isEmpty) return const Text('No items yet.');
              return Column(
                children: [
                  for (final i in items)
                    ListTile(title: Text(i.title), subtitle: Text(i.id)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
