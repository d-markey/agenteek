import 'config_store.dart' show JsonExt;

extension type CustomMcpData._(Map<String, Object?> _json) {
  factory CustomMcpData({
    String? name,
    String? url,
    String? authHeader,
    String? authToken,
  }) => CustomMcpData._({
    kName: ?name?.trim(),
    kUrl: ?url?.trim(),
    kAuthHeader: ?authHeader?.trim(),
    kAuthToken: ?authToken?.trim(),
  });

  factory CustomMcpData.from(Map<String, dynamic> json) =>
      CustomMcpData._({})..set(json);

  void set(Map<String, dynamic>? json) => _json.apply(json, _validKeys);

  static const kName = 'name';
  static const kUrl = 'url';
  static const kAuthHeader = 'auth-header';
  static const kAuthToken = 'auth-token';

  static const _validKeys = {kName, kUrl, kAuthHeader, kAuthToken};

  String get id => name.replaceAll(' ', '_').toLowerCase();

  String get name => _json[kName]?.toString().trim() ?? '';

  Uri? get url {
    final url = _json[kUrl]?.toString().trim() ?? '';
    return url.isEmpty ? null : Uri.parse(url);
  }

  bool get hasAuth => authHeader.isNotEmpty && authToken.isNotEmpty;

  String get authHeader => _json[kAuthHeader]?.toString().trim() ?? '';

  String get authToken => _json[kAuthToken]?.toString().trim() ?? '';
}
