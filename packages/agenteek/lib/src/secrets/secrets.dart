import 'dart:async';

import '_secrets_stub.dart'
    if (dart.library.io) '_secrets_io.dart'
    if (dart.library.js_interop) '_secrets_web.dart'
    as impl;

abstract class Secrets {
  const Secrets();

  FutureOr<String> get(String key);
}

class InMemorySecrets extends Secrets {
  const InMemorySecrets(this._secrets);

  final Map<String, String> _secrets;

  @override
  FutureOr<String> get(String key) => _secrets[key.toLowerCase()] ?? '';

  static Future<Secrets> load(String key) => impl.loadSecrets(key);
}
