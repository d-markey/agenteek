import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:agenteek/agenteek.dart';

import 'agent_config_data.dart';

class ConfigStore {
  static final current = AgentConfigData();

  static final _fs = PersistentFileSystem('config');
  static const _configFileName = 'data.json';
  static bool _configLoaded = false;

  static Future<AgentConfigData?> load() async {
    if (_configLoaded) return current;
    _configLoaded = true;
    if (await _fs.exists(_configFileName)) {
      final content = await _fs.read(_configFileName);
      current.set(jsonDecode(content) as Map<String, dynamic>);
      return current;
    }
    return null;
  }

  static Future<void> save({required Map<String, dynamic> config}) {
    ConfigStore.current.set(config);
    return _fs.write(_configFileName, jsonEncode(config));
  }

  static Future<AgentConfigData?> autoConf(Uri resource) async {
    final res = await web.window.fetch(resource.toString().toJS).toDart;
    final blob = await res.blob().toDart;
    final text = (await blob.text().toDart).toDart;
    if (text.isEmpty) return null;
    final json = jsonDecode(text) as Map<String, dynamic>;
    await save(config: json);
    return AgentConfigData.from(json);
  }
}

extension JsonExt on Map<String, dynamic> {
  void apply(Map<String, dynamic>? json, Set<String> validKeys) {
    clear();
    if (json == null) return;
    for (final entry in json.entries.where(
      (e) => validKeys.contains(e.key) && e.value != null,
    )) {
      this[entry.key] = entry.value.toString().trim();
    }
  }
}
