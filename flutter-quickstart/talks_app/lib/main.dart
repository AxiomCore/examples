import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart' as models;

late final AxiomSdk sdk;

/// The Android emulator reaches your computer at 10.0.2.2.
String backendUrl() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://127.0.0.1:8080';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sdk = await AxiomSdk.create(baseUrlOverrides: {'talks': backendUrl()});
  runApp(const MaterialApp(home: TalksPage()));
}

class TalksPage extends StatelessWidget {
  const TalksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talks')),
      body: AxiomBuilder<models.TalkList, models.TalkList>(
        query: sdk.talks.listTalks(),
        loading: (context) => const Center(child: CircularProgressIndicator()),
        error: (context, error) => Center(child: Text(error.message)),
        builder: (context, state, list) => ListView(
          children: [
            for (final talk in list.talks)
              ListTile(title: Text(talk.title), subtitle: Text(talk.speaker)),
          ],
        ),
      ),
      floatingActionButton: const AddTalkButton(),
    );
  }
}

class AddTalkButton extends StatelessWidget {
  const AddTalkButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AxiomMutationBuilder<models.Talk, String>(
      mutation: AxiomMutation(
        (title) => sdk.talks.createTalk(title: title, speaker: 'You'),
      ),
      builder: (context, state, execute) => FloatingActionButton.extended(
        onPressed: state.isMutating ? null : () => execute('My new talk'),
        label: Text(
          state.data == null ? 'Add talk' : 'Created ${state.data!.id}',
        ),
      ),
    );
  }
}
