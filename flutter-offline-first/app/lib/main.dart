// Offline-first feed: two cached endpoints and pull-to-refresh.
//
// GET /feed/pinned is cache-first (1 hour): while fresh, the cached copy is
// shown and no request is sent. GET /feed/latest is stale-while-revalidate
// (30 s): the cached copy shows at once and a background request refreshes it.
// The runtime cache is persistent (on disk on Android, iOS and macOS, in
// localStorage on the web), so after a restart with the backend down both
// lists still render from the cache.
import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'autorun.dart';
import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart' as models;

late final AxiomSdk sdk;

const _baseUrl = String.fromEnvironment('AXIOM_BASE_URL');

/// The Android emulator reaches your computer at 10.0.2.2.
String backendUrl() {
  if (_baseUrl.isNotEmpty) return _baseUrl;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://127.0.0.1:8080';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sdk = await AxiomSdk.create(baseUrlOverrides: {'feed': backendUrl()});
  runApp(const MaterialApp(home: FeedPage()));
  if (autorunEnabled) await autorun(sdk);
}

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Offline-first feed'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pinned (cache-first)'),
              Tab(text: 'Latest (stale-while-revalidate)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FeedList(query: sdk.feed.pinnedFeed()),
            FeedList(query: sdk.feed.latestFeed()),
          ],
        ),
      ),
    );
  }
}

class FeedList extends StatelessWidget {
  const FeedList({super.key, required this.query});

  final AxiomQuery<models.Feed> query;

  @override
  Widget build(BuildContext context) {
    return AxiomBuilder<models.Feed, models.Feed>(
      query: query,
      loading: (_) => const Center(child: CircularProgressIndicator()),
      // Shown only when there is no cached copy at all.
      error: (_, error) =>
          Center(child: Text('Offline, nothing cached yet.\n${error.message}')),
      builder: (context, state, feed) => RefreshIndicator(
        // Pull to refresh: skip the cache once and fetch from the network.
        onRefresh: () async => query.refresh(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ListTile(
              dense: true,
              leading: Icon(
                state.source == AxiomSource.cache
                    ? Icons.offline_pin
                    : Icons.cloud_done,
              ),
              title: Text(
                'From ${state.source.name}'
                '${state.isFetching ? ', refreshing...' : ''}'
                '${state.hasError ? ' (backend unreachable)' : ''}',
              ),
            ),
            for (final post in feed.posts)
              ListTile(title: Text(post.text), subtitle: Text(post.author)),
          ],
        ),
      ),
    );
  }
}
