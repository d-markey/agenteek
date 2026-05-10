import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
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
    this.tools = const {},
    required super.secrets,
  });

  final String instructionsTemplate;
  final String language;
  final bool codeTools;
  final Map<String, Map<String, Object?>> tools;

  static Future<AgentConf> fromYamlNode(
    File yamlFile,
    MapEntry<String, Map> conf,
    Secrets secrets,
  ) async {
    final role = conf.key;
    final props = conf.value.cast<String, Object?>();

    final llm = props['llm'] as String? ?? 'gemini';
    final apiKeyName = props['api-key'] as String?;

    final name = props['name'] as String;
    final language = props['language'] as String? ?? '';
    final instructor = props['instructor'] as String? ?? '';
    var instructionsTemplate = (props['instructions'] as String)
        .replaceAll('\\t ', '\t')
        .replaceAll('\\r ', '\r')
        .replaceAll('\\n ', '\n')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    if (!instructionsTemplate.contains('\n')) {
      // maybe a file path
      final instrFile = File(
        p.isAbsolute(instructionsTemplate)
            ? instructionsTemplate
            : p.join(yamlFile.absolute.parent.path, instructionsTemplate),
      );
      if (instrFile.existsSync()) {
        instructionsTemplate = await FileReader.readString(instrFile);
      }
    }

    Map<String, Map<String, Object?>> roots;
    final yamlRoots = props['roots'];
    if (yamlRoots == null) {
      roots = const {};
    } else if (yamlRoots is YamlMap) {
      roots = yamlRoots.cast<String, Map>().map(
        (k, v) => MapEntry(k, v.cast<String, Object?>()),
      );
    } else {
      throw UnsupportedError('Invalid format for roots');
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
        (props['mcp'] as Map?)?.cast<String, Map?>().map(
          (k, v) => MapEntry(
            k,
            (v == null)
                ? AccessControlList.allowAll
                : AccessControlList(
                    whiteList: $asStringList(v, 'white-list').map($getPattern),
                    blackList: $asStringList(v, 'black-list').map($getPattern),
                  ),
          ),
        ) ??
        const {};

    Map<String, Map<String, Object?>> tools;
    final yamlTools = props['tools'];
    if (yamlTools == null) {
      tools = const {};
    } else if (yamlTools is YamlMap) {
      tools = yamlTools.cast<String, Map?>().map(
        (k, v) => MapEntry(k, v?.cast<String, Object?>() ?? const {}),
      );
    } else {
      throw UnsupportedError('Invalid format for tools');
    }

    final codeTools = props['code-tools'] as bool? ?? false;

    return AgentConf(
      modelInfo: llm,
      apiKeyName: apiKeyName,
      displayName: name,
      role: role,
      instructor: instructor,
      instructionsTemplate: instructionsTemplate,
      roots: roots,
      mcp: mcp,
      language: language,
      codeTools: codeTools,
      tools: tools,
      secrets: secrets,
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
