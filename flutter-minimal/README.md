# Flutter minimal app

The smallest app on `axiom_flutter`: one generated query (`GET /hello`), one widget, no Material.
Use it to see the fixed cost of the SDK in a release build.

- `api/`: pure Acore backend, `./run-backend.sh` serves it on port 8080 (`PORT=` to change).
- `app/`: Flutter app (Android, iOS, macOS, web); `lib/main.dart` is the whole app;
  `tool/regen.sh` rebuilds the contract and regenerates the client (any OS).

```bash
cd flutter-minimal/api && ./run-backend.sh                       # terminal 1
cd flutter-minimal/app && flutter pub get
flutter run -d chrome --web-port 5000   # web (5000 is in the backend's CORS list)
flutter run -d emulator-5554            # Android emulator (calls http://10.0.2.2:8080)
flutter run -d "iPhone 16"              # iOS simulator (Mac)
flutter run -d macos                    # macOS (Mac)
```

You should see **Hello from Acore** in the middle of the screen (`Loading...` first).

Smoke check: build or run with `--dart-define=AXIOM_EXAMPLE_AUTORUN=true` (and
`--dart-define=AXIOM_BASE_URL=...` for another backend); the log prints
`AXIOM_EXAMPLE hello PASS Hello from Acore` and `AXIOM_EXAMPLE DONE`.

## Release sizes (axiom_flutter 0.150.0)

Measured on 20 Nov 2026 with Flutter 3.32.0 on Linux x86_64, `axiom_flutter` 0.150.0 from pub.dev.
The baseline is `flutter create --empty` (a Material "Hello World!") without any Axiom package,
built the same way. Sizes are bytes as written by the build; the builds are deterministic, so one
build each.

`flutter build apk --release --split-per-abi`:

| ABI | This app | Baseline | Difference | of which `libaxiom_runtime.so` |
| --- | ---: | ---: | ---: | ---: |
| arm64-v8a | 25.1 MB (25,112,306) | 6.6 MB (6,618,467) | +18.5 MB | 10.1 MB |
| armeabi-v7a | 19.2 MB (19,224,920) | 6.0 MB (6,021,406) | +13.2 MB | 7.3 MB |
| x86_64 | 28.7 MB (28,659,017) | 6.7 MB (6,747,536) | +21.9 MB | 12.5 MB |

The native runtime is stored uncompressed in the APK (Android's default for libraries, so it can be
mapped directly). Each APK also carries the web runtime as a Flutter asset
(`axiom_runtime_bg.wasm`, 2.4 MB, 0.95 MB deflated, plus `axiom_runtime.js`), which Android never
uses. Play Store downloads are compressed and smaller than these files.

`flutter build web --release`:

| File | Raw | gzip -9 |
| --- | ---: | ---: |
| `main.dart.js` (this app, widgets only) | 1,156,534 | 349,819 |
| `main.dart.js` (baseline, Material) | 1,632,912 | 478,572 |
| `axiom_runtime_bg.wasm` (Axiom web runtime) | 2,444,563 | 946,955 |
| `axiom_runtime.js` | 38,809 | 7,101 |
| whole `build/web` folder (this app / baseline) | 27,367,610 / 23,693,423 | |

The `build/web` folder includes CanvasKit (`canvaskit.wasm` 7.0 MB, the Chromium variant 5.6 MB
and `skwasm.wasm` 3.4 MB); a browser downloads one of them, the same for any Flutter web app. What
Axiom adds to a page load is the runtime wasm and its loader, about 0.95 MB gzipped. The Dart side
of the SDK is small: this app's `main.dart.js` is smaller than the Material baseline because it does
not use Material.

To measure your own app the same way:

```bash
flutter build apk --release --split-per-abi && ls -l build/app/outputs/flutter-apk/
flutter build web --release && ls -l build/web/main.dart.js build/web/assets/packages/axiom_flutter/lib/assets/wasm/
```
