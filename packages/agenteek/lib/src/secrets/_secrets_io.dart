import 'dart:async';
import 'dart:io' as io;

import 'secrets.dart';

Future<Secrets> loadSecrets(String key) async {
  final file = io.File(key);
  if (!await file.exists()) {
    throw Exception('File "$key" not found.');
  }
  final secrets = <String, String>{};
  final lines = await file.readAsLines();
  for (var line in lines.map((l) => l.trim()).where((l) => l.isNotEmpty)) {
    var idx = line.indexOf(':');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).trim().toLowerCase();
    final value = line.substring(idx + 1).trim();
    secrets[key] = value;
  }
  return InMemorySecrets(secrets);
}

const Secrets environmentSecrets = _EnvironmentSecrets._();

class _EnvironmentSecrets implements Secrets {
  const _EnvironmentSecrets._();

  @override
  String get(String key) => io.Platform.environment[key] ?? '';
}
