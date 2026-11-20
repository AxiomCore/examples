// Headless smoke run (--dart-define=AXIOM_EXAMPLE_AUTORUN=true).
//
// Run it twice: first with the backend up (fills the cache), then stop the
// backend and restart the app (web: reload the page). The second run must
// render both lists from the cache.
import 'package:axiom_flutter/axiom_flutter.dart';
import 'package:flutter/foundation.dart';

import 'axiom_generated/axiom_sdk.dart';
import 'axiom_generated/models.dart' as models;

const autorunEnabled = bool.fromEnvironment('AXIOM_EXAMPLE_AUTORUN');

void _log(String line) => debugPrint('AXIOM_EXAMPLE $line');

/// First state that carries data. Written with `then`: awaiting a query
/// stream inside an `async` function can crash in dart2js builds.
Future<AxiomState<models.Feed>> _firstData(AxiomQuery<models.Feed> q) =>
    q.stream.firstWhere((s) => s.hasData).timeout(const Duration(seconds: 15));

Future<bool> _backendUp(AxiomSdk sdk) => sdk.feed
    .health(options: const AxiomCallOptions(cacheMode: AxiomCacheMode.refresh))
    .stream
    .firstWhere((s) => s.hasData || s.hasError)
    .timeout(const Duration(seconds: 15))
    .then((s) => s.hasData, onError: (Object _) => false);

Future<void> autorun(AxiomSdk sdk) async {
  final up = await _backendUp(sdk);
  _log('backend ${up ? 'up' : 'down'}');
  for (final (name, query) in [
    ('pinned', sdk.feed.pinnedFeed()),
    ('latest', sdk.feed.latestFeed()),
  ]) {
    try {
      final s = await _firstData(query);
      final n = s.data!.posts.length;
      if (n != 3) throw StateError('expected 3 posts, got $n');
      if (!up && s.source != AxiomSource.cache) {
        throw StateError('backend down but source ${s.source.name}');
      }
      _log(
        '${up ? 'online' : 'offline'}-$name PASS $n posts from ${s.source.name}',
      );
    } catch (e) {
      _log('${up ? 'online' : 'offline'}-$name FAIL $e');
    }
  }
  if (up) {
    // Pull-to-refresh path: force a network fetch.
    final q = sdk.feed.latestFeed();
    try {
      q.refresh(force: true);
      final s = await q.stream
          .firstWhere(
            (s) =>
                s.hasData && s.source == AxiomSource.network && !s.isFetching,
          )
          .timeout(const Duration(seconds: 15));
      _log('refresh PASS ${s.data!.posts.length} posts from network');
    } catch (e) {
      _log('refresh FAIL $e');
    }
  }
  _log('DONE');
}
