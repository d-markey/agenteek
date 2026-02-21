import 'package:agenteek/agenteek.dart';
import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

class AgentConf extends AgentConfiguration {
  AgentConf({
    required super.modelInfo,
    super.apiKeyName,
    required super.displayName,
    required super.role,
    required this.instructionsTemplate,
    super.instructor,
    super.roots,
    super.mcp,
    this.language = '',
    this.codeTools = false,
    this.tools = const [],
  });

  final String instructionsTemplate;
  final String language;
  final bool codeTools;
  final List<String> tools;

  factory AgentConf.fromYamlNode(MapEntry<String, Map> conf) {
    final role = conf.key;
    final props = conf.value.cast<String, Object?>();

    final llm = props['llm'] as String? ?? 'gemini';
    final apiKeyName = props['api-key'] as String?;

    final name = props['name'] as String;
    final language = props['language'] as String? ?? '';
    final instructor = props['instructor'] as String? ?? '';
    final instructions = (props['instructions'] as String);

    Map<String, Map<String, String>> roots;
    final yamlRoots = props['roots'];
    if (yamlRoots == null) {
      roots = const {};
    } else if (yamlRoots is YamlMap) {
      roots = yamlRoots.cast<String, Map>().map(
        (k, v) => MapEntry(k, v.cast<String, String>()),
      );
    } else {
      throw UnsupportedError('message');
    }

    List<String> $asStringList(Map map, String key) {
      final list = map[key];
      if (list == null) {
        return const [];
      } else if (list is String) {
        return list.isEmpty ? const [] : [list];
      } else if (list is List) {
        return list.map((s) => s as String).where((s) => s.isNotEmpty).toList();
      }
      throw UnsupportedError('String or list of string expected: $list');
    }

    Pattern $getPattern(String v) => (v.startsWith('/') && v.endsWith('/'))
        ? RegExp(v.substring(1, v.length - 1))
        : ((Glob.quote(v) == v) ? v : Glob(v, caseSensitive: false));

    final mcp =
        (props['mcp'] as Map?)?.cast<String, Map>().map(
          (k, v) => MapEntry(
            k,
            AccessControlList(
              whiteList: $asStringList(v, 'white-list').map($getPattern),
              blackList: $asStringList(v, 'black-list').map($getPattern),
            ),
          ),
        ) ??
        const {};

    final tools = (props['tools'] as List?)?.cast<String>() ?? const [];
    final codeTools = props['code-tools'] as bool? ?? false;

    return AgentConf(
      modelInfo: llm,
      apiKeyName: apiKeyName,
      displayName: name,
      role: role,
      instructor: instructor,
      instructionsTemplate: instructions
          .replaceAll('\\n ', '\n')
          .replaceAll('\\n', ''),
      roots: roots,
      mcp: mcp,
      language: language,
      codeTools: codeTools,
      tools: tools,
    );
  }

  void prepareInstructions() {
    final uninterpolatedVariables =
        RegExp(
              '^\\{[a-zA-Z0-9_]+\\}|[^\$]\\{[a-zA-Z0-9_]+\\}|\\\$[a-zA-Z0-9_]+',
            )
            .allMatches(instructionsTemplate)
            .map((m) => m.group(1) ?? '')
            .map(
              (t) => (!t.startsWith('{') && !t.startsWith('\$'))
                  ? t.substring(1)
                  : t,
            )
            .toList();
    if (uninterpolatedVariables.isNotEmpty) {
      print(
        'Warning: detected uninterpolated variables: ${uninterpolatedVariables.join(', ')}.',
      );
    }

    instructions = instructionsTemplate
        .replaceAll(r'${role}', role)
        .replaceAll(r'${name}', displayName)
        .replaceAll(r'${language}', language)
        .replaceAll(r'${team}', team.join(', '))
        .trim();
  }
}
