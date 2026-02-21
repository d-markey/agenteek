import 'package:agenteek/src/utils/unique_id.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../secrets/secrets.dart';
import '../toolsets/toolset.dart';
import '../utils/access_control_list.dart';

final _uniqueId = UniqueIdGenerator();

class AgentConfiguration {
  AgentConfiguration({
    required String modelInfo,
    this.apiKeyName,
    required this.displayName,
    this.role = '',
    this.instructor = '',
    this.roots = const {},
    this.mcp = const {},
    Secrets? secrets,
  }) : _modelInfo = dartantic.ModelStringParser.parse(modelInfo) {
    final apiKeyName = this.apiKeyName ?? '';
    if (apiKeyName.isNotEmpty) {
      // lookup api key
      if (secrets == null) throw ArgumentError.notNull('secrets');
      final apiKey = secrets.get(apiKeyName);
      if (apiKey is String) {
        // register a custom provider (sync route)
        _setupCustomProvider(apiKey);
      } else {
        // register a custom provider (async route)
        apiKey.then(
          _setupCustomProvider,
          onError: (ex) {
            print('!!! Failed to setup custom provider for $_modelInfo');
          },
        );
      }
    } else {
      _customModelInfo = null;
    }
  }

  final dartantic.ModelStringParser _modelInfo;
  late final dartantic.ModelStringParser? _customModelInfo;

  String get modelInfo => (_customModelInfo ?? _modelInfo).toString();

  final String? apiKeyName;
  final String displayName;
  final String role;
  final String instructor;
  final Map<String, Map<String, String>> roots;
  final Map<String, AccessControlList> mcp;

  final _team = <String>[];
  Iterable<String> get team => _team;

  final _toolSets = <ToolSet>[];
  Iterable<ToolSet> get toolSets => _toolSets;

  void _setupCustomProvider(String apiKey) {
    if (apiKey.isEmpty) throw StateError('API Key "$apiKeyName" not found.');

    final factoryId = _modelInfo.providerName.toLowerCase();
    final provider = dartantic.Agent.providerFactories[factoryId]?.call();
    if (provider == null) {
      throw StateError(
        'Unsupported provider name: "${_modelInfo.providerName}".',
      );
    }

    final customModelInfo = _customModelInfo = _modelInfo.copyWith(
      providerName: '$factoryId-${_uniqueId.string(6).toLowerCase()}',
      chatModelName:
          // force cat model name
          _modelInfo.chatModelName ??
          provider.defaultModelNames[dartantic.ModelKind.chat]!,
    );

    final dartantic.Provider Function() customProvider;
    switch (provider) {
      case dartantic.AnthropicProvider _:
      case dartantic.OllamaProvider _:
        throw UnimplementedError(
          'Unimplemented custom provider for ${provider.runtimeType}.',
        );

      case dartantic.CohereProvider _:
        customProvider = () => dartantic.CohereProvider(apiKey: apiKey);

      case dartantic.GoogleProvider _:
        customProvider = () => dartantic.GoogleProvider(apiKey: apiKey);

      case dartantic.MistralProvider _:
        customProvider = () => dartantic.MistralProvider(apiKey: apiKey);

      case dartantic.OpenAIProvider _:
        customProvider = () => dartantic.OpenAIProvider(apiKey: apiKey);
      case dartantic.OpenAIResponsesProvider _:
        customProvider = () =>
            dartantic.OpenAIResponsesProvider(apiKey: apiKey);

      default:
        throw StateError(
          'Unsupported provider: ${provider.runtimeType} "${_modelInfo.providerName}".',
        );
    }

    dartantic.Agent.providerFactories[customModelInfo.providerName] =
        customProvider;

    print('Registered provider for ${customModelInfo.toString()}');
  }

  String _instructions = '';
  String get instructions => _instructions;
  set instructions(String value) {
    if (_instructions.isEmpty) {
      _instructions = value;
    }
  }

  void registerTeamMember(String name) => _team.add(name);

  void registerToolSet(ToolSet toolSet) => _toolSets.add(toolSet);
}

extension on dartantic.ModelStringParser {
  dartantic.ModelStringParser copyWith({
    String? providerName,
    String? chatModelName,
    String? embeddingsModelName,
    String? mediaModelName,
  }) => dartantic.ModelStringParser(
    providerName ?? this.providerName,
    chatModelName: chatModelName ?? this.chatModelName,
    embeddingsModelName: embeddingsModelName ?? this.embeddingsModelName,
    mediaModelName: mediaModelName ?? this.mediaModelName,
  );
}
