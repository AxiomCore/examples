import 'package:flutter/foundation.dart';

/// On Android, iOS and macOS close the app and start it again: the session is
/// restored from the Keychain / Keystore.
void restartApp() =>
    debugPrint('AXIOM_EXAMPLE restart the app now to test session restore');
