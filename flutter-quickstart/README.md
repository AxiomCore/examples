# Flutter quickstart: talks app

This is the finished result of the public tutorial
[Build a Flutter app on a contract](https://docs.axiomcore.dev/getting-started/quickstart-flutter/).
`talks-api/main.acore` and `talks_app/lib/main.dart` are identical to the page. Use it to compare
with your own attempt, or to run the result directly.

| Path | What it is |
| --- | --- |
| `talks-api/` | Pure Acore backend: `GET /talks`, `POST /talks`, CORS for `http://localhost:5000` and `http://127.0.0.1:5000` |
| `talks-api/run-backend.sh` | `axiom check`, `axiom build`, `axiom server deployment`, `axiom run` on port 8080 (`PORT=` to change) |
| `talks_app/` | Flutter app (Android, iOS, macOS, web) with the generated client in `lib/axiom_generated/` |
| `talks_app/tool/regen.sh` | Rebuild the contract and run `axiom pull` again (any OS, no Mac needed) |
| `talks_app/tool/autorun_main.dart` | Headless smoke check (not in the tutorial) |

Versions: Axiom CLI 0.156.0, Flutter 3.32 or newer, `axiom_flutter` and
`axiom_flutter_generator` 0.150.0 from pub.dev.

## Run it

Terminal 1, the backend:

```bash
cd flutter-quickstart/talks-api
./run-backend.sh
curl -s http://127.0.0.1:8080/talks
```

You should see `{"talks":[{"id":"t1",...},{"id":"t2",...}]}`.

Terminal 2, the app:

```bash
cd flutter-quickstart/talks_app
flutter pub get
flutter run -d chrome --web-port 5000      # web: the port must be 5000 (CORS)
flutter run -d emulator-5554               # Android emulator (x86_64 or arm64); app calls http://10.0.2.2:8080
flutter run -d "iPhone 16"                 # iOS simulator (needs a Mac, Xcode, CocoaPods)
flutter run -d macos                       # macOS (needs a Mac)
```

What you should see: the **Talks** screen lists **Typed APIs in Flutter** (Ada) and **Contracts
over REST** (Grace). Press **Add talk**: the button changes to **Created t3**. The backend prints
a `response.validated` line for `listTalks` and one for `createTalk`.

## Regenerate the client

After you change `talks-api/main.acore`:

```bash
cd flutter-quickstart/talks_app
tool/regen.sh            # AXIOM=/path/to/axiom tool/regen.sh for another CLI
flutter analyze
```

Then restart the backend so it serves the new contract.

## Smoke check (CI or headless)

```bash
cd flutter-quickstart/talks-api && PORT=8701 ./run-backend.sh &
cd flutter-quickstart/talks_app
flutter build web --profile -t tool/autorun_main.dart --dart-define=AXIOM_BASE_URL=http://127.0.0.1:8701
# serve build/web on http://127.0.0.1:5000 and open it in Chrome; the console prints
#   AXIOM_EXAMPLE init PASS
#   AXIOM_EXAMPLE listTalks PASS Typed APIs in Flutter/Ada, Contracts over REST/Grace
#   AXIOM_EXAMPLE createTalk PASS Created t3
#   AXIOM_EXAMPLE DONE
```

On a device: `flutter run -d <device> -t tool/autorun_main.dart` (Android emulator: add
`--dart-define=AXIOM_BASE_URL=http://10.0.2.2:8080`) and look for `AXIOM_EXAMPLE` in the log.

## Differences from what `flutter create` gives you

- `test/widget_test.dart` is removed: it refers to the template's `MyApp`, which the tutorial's
  `main.dart` replaces, so `flutter analyze` would report an error in it.
- Platform setup from step 5 of the tutorial is applied: `minSdk = 24`, `INTERNET`, debug-only
  cleartext to `10.0.2.2` (`android/app/src/debug/`), iOS 13.0 and `NSAllowsLocalNetworking`,
  macOS 11.0 and `com.apple.security.network.client` in both entitlement files, Podfiles with
  `platform :ios, '13.0'` / `platform :osx, '11.0'`.
- `AxiomDeps.toml` records the contract as `../talks-api/backend.axiom`; `axiom pull` writes an
  absolute path, and `tool/regen.sh` turns it back into a relative one.

`flutter build apk` prints a warning that `axiom_flutter` and `path_provider_android` want Android
NDK 27.0.12077973. The build succeeds with the Flutter default; add `ndkVersion = "27.0.12077973"`
to `android/app/build.gradle.kts` to silence it.
