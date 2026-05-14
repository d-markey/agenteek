import 'package:agenteek/agenteek.dart';

extension type MemorizeTopicArgs(Json _json) {
  String get topic => _json.getString('topic').toLowerCase();

  String get information => _json.getString('information');

  String get mode {
    final mode = _json.getString('mode', defaultValue: 'update').toLowerCase();
    return (mode == 'replace' || mode == 'update')
        ? mode
        : throw 'Invalid mode: $mode';
  }

  static final schema = S.object(
    properties: {
      'topic': S.string(description: 'Topic to memorize'),
      'information': S.string(description: 'Information about the topic'),
      'mode': S.string(
        description:
            'Memorization mode, one of: '
                    '`replace` to replace any pre-existing information with new information, '
                    'or `update` to append new information while retaining existing information'
                .optional('update'),
      ),
    },
    required: ['topic', 'information'],
  );
}

extension type RecallTopicArgs(Json _json) {
  String get topic => _json.getString('topic').toLowerCase();

  static final schema = S.object(
    properties: {'topic': S.string(description: 'Topic to recall')},
    required: ['topic'],
  );
}

extension type ForgetTopicArgs(Json _json) {
  String get topic => _json.getString('topic').toLowerCase();

  static final schema = S.object(
    properties: {'topic': S.string(description: 'Topic to forget')},
    required: ['topic'],
  );
}
