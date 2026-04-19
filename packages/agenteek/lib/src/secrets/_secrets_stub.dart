import 'dart:async';

import 'in_memory_secrets.dart';
import 'secrets.dart';

Future<Secrets> loadSecrets(String key) =>
    throw UnsupportedError('Unsupported platform.');

const Secrets environmentSecrets = InMemorySecrets({});
