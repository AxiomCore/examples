import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/material.dart';

import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart' as models;

late final AxiomSdk sdk;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Starts the runtime and loads assets/axiom/rpc.axiom. The base URL comes
  // from AxiomDeps.toml (http://127.0.0.1:8000); override it at run time with
  // --dart-define=AXIOM_BASE_URL=http://10.0.2.2:8000 (Android emulator).
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

  runApp(const MaterialApp(home: RpcDemoScreen()));

  // Smoke mode for CI / headless runs: call the RPC once and print the result.
  if (const bool.fromEnvironment('AXIOM_EXAMPLE_AUTORUN')) {
    // `then` instead of `await`: with axiom_flutter 0.147.5 on web (dart2js),
    // awaiting a query stream inside an `async` function can crash.
    const models.Person(id: 'USR-9921', name: 'Example person')
        .getContacts(sdk, limit: 10)
        .stream
        .firstWhere((s) => s.hasData || s.hasError)
        .then((state) {
          debugPrint(
            state.hasData
                ? 'AXIOM_EXAMPLE rpc PASS ${state.data}'
                : 'AXIOM_EXAMPLE rpc FAIL ${state.error?.message}',
          );
          debugPrint('AXIOM_EXAMPLE DONE');
        });
  }
}

/// The contract declares `Person.rpcs.get_contacts`, resolved to
/// `POST /collections` with body `{max_results: $args.limit, person_id: $this.id}`.
///
/// axiom_flutter_generator does not emit model RPC methods yet, so this
/// extension spells out the same resolver by hand on top of the generated
/// endpoint id.
extension PersonRpc on models.Person {
  AxiomQuery<Object?> getContacts(AxiomSdk sdk, {required int limit}) {
    return sdk.runtime.sendMutation<Object?>(
      namespace: 'rpc',
      endpointId: RpcModule.endpointIds['create_collection']!,
      method: 'POST',
      path: '/collections',
      body: {'max_results': limit, 'person_id': id},
      decoder: (json) => json,
    );
  }
}

class RpcDemoScreen extends StatefulWidget {
  const RpcDemoScreen({super.key});

  @override
  State<RpcDemoScreen> createState() => _RpcDemoScreenState();
}

class _RpcDemoScreenState extends State<RpcDemoScreen> {
  // Usually this would come from a previous query.
  final person = const models.Person(id: 'USR-9921', name: 'Example person');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RPC demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Active user: ${person.name}'),
            const SizedBox(height: 20),
            AxiomMutationBuilder<Object?, int>(
              mutation: AxiomMutation(
                (limit) => person.getContacts(sdk, limit: limit),
              ),
              builder: (context, state, execute) {
                return Column(
                  children: [
                    ElevatedButton(
                      key: const Key('get-contacts'),
                      onPressed: state.isMutating ? null : () => execute(10),
                      child: Text(
                        state.isMutating ? 'Fetching...' : 'Get contacts (RPC)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (state.hasData)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.green.shade50,
                        child: Text(
                          'Server response: ${(state.data as Map?)?['message']}',
                        ),
                      ),
                    if (state.hasError)
                      Text(
                        'Error: ${state.error?.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
