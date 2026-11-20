# Flutter offline-first feed

A feed that keeps working without the backend. The contract declares the cache per endpoint and
the runtime's persistent cache does the rest; the app has no caching code of its own.

| Endpoint | Cache in `feed-api/main.acore` | What the app does |
| --- | --- | --- |
| `GET /feed/pinned` | `cache(strategy: CacheStrategy.cacheFirst, ttl: 1h)` | Served from the cache while fresh; no request at all |
| `GET /feed/latest` | `cache(strategy: CacheStrategy.staleWhileRevalidate, ttl: 30s)` | Cached copy at once, background refresh |
| `GET /health` | none | Used by the smoke run to see whether the backend is up |

Pull down on a list to refresh it from the network (`query.refresh(force: true)`). Each list shows
where its data came from (`state.source`: cache or network) and whether a refresh is running.
The cache is on disk on Android, iOS and macOS and in `localStorage` on the web, so it survives an
app restart or a page reload.

Backend: pure Acore (`feed-api/`), `run-backend.sh` serves it on port 8080 (`PORT=` to change).
App: `app/` (Android, iOS, macOS, web), generated client in `lib/axiom_generated/`,
`tool/regen.sh` to rebuild the contract and regenerate (any OS). axiom_flutter 0.150.0, CLI 0.156.0.

## Run it

```bash
cd flutter-offline-first/feed-api && ./run-backend.sh          # terminal 1
cd flutter-offline-first/app && flutter pub get
flutter run -d chrome --web-port 5000      # web (5000 is in the backend's CORS list)
flutter run -d emulator-5554               # Android emulator, calls http://10.0.2.2:8080
flutter run -d "iPhone 16"                 # iOS simulator (Mac)
flutter run -d macos                       # macOS (Mac)
```

What you should see:

1. Both tabs (**Pinned (cache-first)**, **Latest (stale-while-revalidate)**) show three posts by
   Ada, Grace and Linus, marked **From network**.
2. Stop the backend (Ctrl-C) and restart the app (web: reload the page). Both tabs still show the
   three posts, marked **From cache**; Latest adds **(backend unreachable)** after its background
   refresh fails.
3. Start the backend again and pull down on a list: it shows **From network** again.

## Smoke check (headless)

```bash
cd flutter-offline-first/app
flutter build web --profile --dart-define=AXIOM_EXAMPLE_AUTORUN=true --dart-define=AXIOM_BASE_URL=http://127.0.0.1:8080
# serve build/web on http://127.0.0.1:5000, open it in Chrome with the backend up:
#   AXIOM_EXAMPLE backend up
#   AXIOM_EXAMPLE online-pinned PASS 3 posts from network
#   AXIOM_EXAMPLE online-latest PASS 3 posts from network
#   AXIOM_EXAMPLE refresh PASS 3 posts from network
#   AXIOM_EXAMPLE DONE
# stop the backend, reload the page (same browser profile):
#   AXIOM_EXAMPLE backend down
#   AXIOM_EXAMPLE offline-pinned PASS 3 posts from cache
#   AXIOM_EXAMPLE offline-latest PASS 3 posts from cache
#   AXIOM_EXAMPLE DONE
```

On a device: `flutter run -d <device> --dart-define=AXIOM_EXAMPLE_AUTORUN=true` (Android emulator
adds `--dart-define=AXIOM_BASE_URL=http://10.0.2.2:8080`), then stop the backend, close the app and
start it again with the same command.

Note for headless checks with the Chrome DevTools protocol: `Runtime.enable` replays the console
messages of the page that is already open, so navigate to `about:blank` between the two runs.
