import 'package:agenteek/agenteek.dart';

extension type SendMessageArgs(Json _json) {
  String get agent => _json.getString('agent');

  String get prompt => _json.getString('prompt');

  static final schema = S.object(
    properties: {
      'agent': S.string(description: 'The target Agent.'),
      'prompt': S.string(description: 'Instructions for the Agent.'),
    },
    required: ['prompt', 'agent'],
  );
}

extension type ClearHistoryArgs(Json _json) {
  String get agent => _json.getString('agent');

  static final schema = S.object(
    properties: {'agent': S.string(description: 'The target Agent.')},
    required: ['agent'],
  );
}
