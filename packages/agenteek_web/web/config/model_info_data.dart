import 'config_store.dart' show JsonExt;

extension type ModelInfoData._(Map<String, Object?> _json) {
  factory ModelInfoData({String? id, String? apiKey}) =>
      ModelInfoData._({kId: ?id?.trim(), kApiKey: ?apiKey?.trim()});

  factory ModelInfoData.from(Map<String, dynamic> json) =>
      ModelInfoData._({})..set(json);

  void set(Map<String, dynamic>? json) => _json.apply(json, _validKeys);

  static const kId = 'id';
  static const kApiKey = 'api-key';

  static const _validKeys = {kId, kApiKey};

  bool get isSet => id.isNotEmpty && apiKey.isNotEmpty;

  String get id => _json[kId] as String? ?? '';

  String get apiKey => _json[kApiKey] as String? ?? '';
}
