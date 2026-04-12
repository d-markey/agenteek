import 'model_info_data.dart';
import 'custom_mcp_data.dart';

extension type AgentConfigData._(Map<String, Object?> _json) {
  factory AgentConfigData({
    ModelInfoData? modelInfo,
    String? githubPat,
    Iterable<CustomMcpData>? customMcpServers,
  }) {
    githubPat = githubPat?.trim() ?? '';
    customMcpServers ??= const [];

    return AgentConfigData._({
      kModelInfo: modelInfo ?? ModelInfoData(),
      if (githubPat.isNotEmpty) kGithubPat: githubPat,
      if (customMcpServers.isNotEmpty) kCustomMcp: customMcpServers,
    });
  }

  factory AgentConfigData.from(Map<String, dynamic> json) =>
      AgentConfigData()..set(json);

  void set(Map<String, dynamic>? json) {
    json ??= const {};

    List<CustomMcpData> customMcps = [];
    String? githubPat;

    for (final entry in json.entries) {
      switch (entry.key) {
        case kModelInfo:
          // only one model info is allowed
          final json = (entry.value as Iterable)
              .cast<Map<String, dynamic>>()
              .single;
          modelInfo.set(json);
          break;

        case kCustomMcp:
          // multiple custom mcp servers are allowed
          if (entry.value case Iterable mcps) {
            for (var mcp in mcps.cast<Map<String, dynamic>>()) {
              customMcps.add(CustomMcpData.from(mcp));
            }
          }
          break;

        case kGithubPat:
          githubPat = entry.value?.toString();
          break;
      }
    }

    if (customMcps.isNotEmpty) _json[kCustomMcp] = customMcps;
    if (githubPat != null) _json[kGithubPat] = githubPat;
  }

  static const kGithubPat = 'github-pat';
  static const kModelInfo = 'model-info';
  static const kCustomMcp = 'custom-mcp';

  ModelInfoData get modelInfo => _json[kModelInfo] as ModelInfoData;

  String get githubPat => (_json[kGithubPat] as String?) ?? '';

  Iterable<CustomMcpData> get mcpServers =>
      _json[kCustomMcp] as List<CustomMcpData>? ?? const [];

  Iterable<CustomMcpData> get authMcpServers =>
      mcpServers.where((mcp) => mcp.hasAuth);
}
