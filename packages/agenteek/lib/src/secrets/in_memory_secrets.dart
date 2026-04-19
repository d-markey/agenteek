import 'dart:async';

import 'secrets.dart';

/// A collection of secrets in memory.
class InMemorySecrets extends Secrets {
  const InMemorySecrets(this._secrets);

  final Map<String, String> _secrets;

  @override
  FutureOr<String> get(String key) => _secrets[key.toLowerCase()] ?? '';
}
