import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'secrets.dart';

Future<Secrets> loadSecrets(String key) {
  if (web.window.isUndefinedOrNull) {
    throw Exception('Cannot access local storage.');
  }
  final json = web.window.localStorage.getItem(key);
  if (json == null) {
    throw Exception('Key "$key" not found.');
  }
  try {
    final secrets = (jsonDecode(json) as Map).cast<String, String>();
    return Future.value(InMemorySecrets(secrets));
  } catch (ex, st) {
    Error.throwWithStackTrace(
      Exception('Invalid content for key "$key": $ex'),
      st,
    );
  }
}
