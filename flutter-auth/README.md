# Flutter managed sign-in (axiom_flutter_auth)

Sign-up, sign-in, session restore and sign-out with
[`axiom_flutter_auth`](https://pub.dev/packages/axiom_flutter_auth) 0.150.0 against a local
issuer (`axiom auth emulate`), and a pure Acore backend whose `GET /me` is guarded: it answers
only with a token from that issuer. `AxiomAuthBinding.attach(auth, runtime: sdk.runtime,
namespaces: ['api'])` gives the token to the `api` contract only.

| Path | What it is |
| --- | --- |
| `api/main.acore` | `GET /health` (open), `GET /me` (`guard signedIn`, returns `Principal.subject`), CORS for `http://localhost:5173` and `http://127.0.0.1:5173` |
| `api/run-emulator.sh` | `axiom auth emulate --port 8710` (issuer `http://127.0.0.1:8710/local/api`) |
| `api/run-backend.sh` | build, scaffold a deployment, point it at the emulator (`axiom auth emulate deployment`), run on port 8711 |
| `app/` | Flutter app (Android, iOS, macOS, web); `lib/main.dart` is the app, `lib/autorun.dart` the smoke run |
| `app/tool/create_user.py` | creates a verified user on the emulator (reads the code from the mail store) |
| `app/tool/regen.sh` | rebuild the contract and run `axiom pull` again (any OS) |

Needs Axiom CLI 0.156.0 (auth emulation needs 0.151.0+), Flutter 3.32+, Python 3 for the helper.

## Run it

```bash
cd flutter-auth/api
./run-emulator.sh                 # terminal 1; keep running
./run-backend.sh                  # terminal 2; restart it whenever you restart the emulator (new keys)
curl -si http://127.0.0.1:8711/me | head -1        # HTTP/1.1 401 Unauthorized
```

If the emulator fails with a SQLite version error (Debian 12 ships 3.40, it needs 3.44+), build or
install a newer `libsqlite3.so.0` and start it with `AXIOM_SQLITE_LIBRARY=/path/to/libsqlite3.so.0`.
Outside a linked Cloud project the CLI may ask you to log in; set
`AXIOM_CLOUD_URL=http://127.0.0.1:9` (the emulator makes no Cloud call).

Terminal 3, the app:

```bash
cd flutter-auth/app
flutter pub get
flutter run -d chrome --web-port 5173     # web: 5173 is the emulator's allowed origin and the backend's CORS origin
flutter run -d emulator-5554              # Android emulator: issuer and API on 10.0.2.2
flutter run -d "iPhone 16"                # iOS simulator (Mac)
flutter run -d macos                      # macOS (Mac)
```

What you should see: **Sign in** with Email and Password. Type an address and a password of 8+
characters, press **Create account**; the code appears in the emulator's mail viewer
(`http://127.0.0.1:8710/local/mail`). Enter it and press **Verify and sign in**: the **Signed in**
screen shows "Hello from a protected endpoint" and your subject (a UUID) from `GET /me`. Restart
the app (web: reload the page): you stay signed in (Keychain / Keystore, `sessionStorage` on the
web). **Sign out** returns to the sign-in screen and `GET /me` is refused again. Or create a user
with `python3 tool/create_user.py` and sign in with it (password `correct horse battery`).

Other hosts and ports: `--dart-define=AXIOM_AUTH_ISSUER=...` and `--dart-define=AXIOM_BASE_URL=...`.

## Smoke check (headless)

```bash
cd flutter-auth/app
EMAIL=$(python3 tool/create_user.py)
flutter build web --profile --dart-define=AXIOM_EXAMPLE_AUTORUN=true --dart-define=AXIOM_EXAMPLE_EMAIL=$EMAIL
# serve build/web on http://127.0.0.1:5173 and open it in Chrome; the console prints
#   AXIOM_EXAMPLE restore-empty PASS anonymous
#   AXIOM_EXAMPLE me-signed-out PASS 401
#   AXIOM_EXAMPLE sign-in PASS authenticated
#   AXIOM_EXAMPLE me-signed-in PASS <subject>
#   (the page reloads itself)
#   AXIOM_EXAMPLE restore PASS authenticated <subject>
#   AXIOM_EXAMPLE me-restored PASS <subject>
#   AXIOM_EXAMPLE sign-out PASS anonymous
#   AXIOM_EXAMPLE me-after-sign-out PASS 401
#   AXIOM_EXAMPLE DONE
```

On a device the same define runs the first half; close and reopen the app (keep the defines) for
the restore half.

## Platform notes

- Android: `minSdk = 24` (axiom_flutter), `compileSdk = 36` (flutter_secure_storage 10), INTERNET,
  debug-only cleartext to `10.0.2.2`. Provider sign-in (not used here) also needs the
  flutter_web_auth_2 `CallbackActivity`; see the axiom_flutter_auth README.
- iOS 13.0 with `NSAllowsLocalNetworking`; macOS 11.0 with `com.apple.security.network.client`.
  macOS uses the legacy login keychain (default `secureStorage()`), so no Keychain Sharing
  entitlement is needed.
- Web: the refresh record is in `sessionStorage` (survives a reload, readable by any script on the
  page). Use it only with a strict Content-Security-Policy, or use `memoryStorage()`.
