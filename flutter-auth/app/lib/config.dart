import 'package:flutter/foundation.dart';

/// The Android emulator reaches your computer at 10.0.2.2.
String _host() => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? '10.0.2.2'
    : '127.0.0.1';

const _issuer = String.fromEnvironment('AXIOM_AUTH_ISSUER');
const _api = String.fromEnvironment('AXIOM_BASE_URL');

/// `axiom auth emulate --port 8710` in api/ prints this issuer.
String issuerUrl() =>
    _issuer.isNotEmpty ? _issuer : 'http://${_host()}:8710/local/api';

/// `api/run-backend.sh` serves the contract on port 8711.
String apiUrl() => _api.isNotEmpty ? _api : 'http://${_host()}:8711';
