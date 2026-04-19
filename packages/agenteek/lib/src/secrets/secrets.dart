import 'dart:async';

import '_secrets_stub.dart'
    if (dart.library.io) '_secrets_io.dart'
    if (dart.library.js_interop) '_secrets_web.dart'
    as impl;

/// A collection of secrets.
abstract class Secrets {
  const Secrets();

  /// Gets the value of the secret with the given [key].
  /// If the secret is not found, returns an empty string.
  FutureOr<String> get(String key);

  /// Loads secrets from a file (`io`) or from local storage (`web`).
  /// On native platform, [key] is the path to the file.
  /// On web platform, [key] is the key to use in local storage.
  static Future<Secrets> load(String key) => impl.loadSecrets(key);
}

/// On Web platform, this is an empty map.
/// On native platform, this is a map of environment variables.
const Secrets environmentSecrets = impl.environmentSecrets;
