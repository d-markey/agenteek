import 'dart:convert';

import 'package:agenteek/agenteek.dart';
import 'package:dartantic_interface/dartantic_interface.dart' as ai_;

/// A `ToolSet` that provides tools for managing memory.
/// The default implementation uses in-memory storage (information is lost
/// when the process exits).
class MemoryToolSet extends ToolSet {
  /// Initializes a new instance of the `MemoryToolSet`.
  MemoryToolSet({
    required this.prefix,
    required String owner,
    String? scope,
    FileSystem? fileSystem,
  }) : _fileSystem = fileSystem ?? MemoryFileSystem(),
       scope = scope?.trim() ?? '',
       _fileName = 'memory_$owner.json',
       _logger = Log('memory_$owner') {
    // register tools
    register(_listTopicsSpec);
    register(_recallTopicSpec);
    register(_memorizeTopicSpec);
    register(_forgetTopicSpec);
  }

  /// The prefix used as a namespace for file-related tools.
  final String prefix;

  /// A description of the scope covered by this toolset.
  final String scope;

  final FileSystem _fileSystem;
  final String _fileName;
  final Log _logger;

  final _topics = <String, String>{};

  Future<Map<String, String>> _sync() async {
    if (await _fileSystem.exists(_fileName)) {
      final topics = (jsonDecode(await _fileSystem.read(_fileName)) as Map)
          .cast<String, String>();
      for (var entry in topics.entries) {
        final topic = entry.key.toLowerCase();
        if (!_topics.containsKey(topic)) {
          _topics[topic] = entry.value;
        }
      }
    }
    return _topics;
  }

  /// Lists all topics held in memory.
  ai_.Tool get _listTopicsSpec => ai_.Tool(
    name: '${prefix}_list_topics',
    description: _scoped('List all topics held in memory'),
    onCall: (args) => _sync().then((_) => {'topics': _topics.keys.toList()}),
  );

  /// Recall a topic.
  ai_.Tool get _recallTopicSpec => ai_.Tool(
    name: '${prefix}_recall_topic',
    description: _scoped('Loads information related to a topic from memory'),
    inputSchema: z.object(
      {'topic': z.string('Topic to recall')},
      required: ['topic'],
    ),
    onCall: (args) {
      args as Json;
      final topic = (args['topic'] as String?)?.trim().toLowerCase() ?? '';
      if (topic.isEmpty) throw Exception('ERROR: missing topic.');
      return _topics.containsKey(topic)
          ? Future.value(_topics[topic]!)
          : _sync().then(($) => $[topic] ?? 'Unknown topic');
    },
  );

  /// Remember information about a topic.
  ai_.Tool get _memorizeTopicSpec => ai_.Tool(
    name: '${prefix}_memorize_topic',
    description: _scoped(
      'Associate information to a topic in memory; if the topic is already present in memory, the provided information is concatenated with the existing information',
    ),
    inputSchema: z.object(
      {
        'topic': z.string('Topic'),
        'information': z.string('Information about the topic'),
        'mode': z.string(
          'Memorization mode, one of: '
          '`set` to replace any pre-existing information with new information, '
          'or `update` to append new information while retaining existing information',
        ),
      },
      required: ['topic', 'information', 'mode'],
    ),
    onCall: (args) async {
      args as Json;
      // load args
      final topic = (args['topic'] as String?)?.trim().toLowerCase() ?? '';
      var information = (args['information'] as String?)?.trim() ?? '';
      final mode = (args['mode'] as String?)?.trim().toLowerCase() ?? '';
      if (topic.isEmpty) throw Exception('ERROR: missing topic.');
      if (information.isEmpty) throw Exception('ERROR: missing information.');
      if (mode.isEmpty || (mode != 'set' && mode != 'update')) {
        throw Exception('ERROR: invalid mode: "$mode".');
      }
      await _sync();
      if (mode == 'update') {
        final existing = _topics[topic] ?? '';
        if (existing.isNotEmpty) {
          information = '$existing\n\n$information';
        }
      }
      _topics[topic] = information;
      await _fileSystem.write(_fileName, jsonEncode(_topics));
      return "OK";
    },
  );

  /// Forget information about a topic.
  ai_.Tool get _forgetTopicSpec => ai_.Tool(
    name: '${prefix}_forget_topic',
    description: _scoped('Forget information about a topic'),
    inputSchema: z.object({'topic': z.string('Topic')}, required: ['topic']),
    onCall: (args) async {
      args as Json;
      final topic = (args['topic'] as String?)?.trim().toLowerCase() ?? '';
      if (topic.isEmpty) throw Exception('ERROR: missing topic.');
      await _sync();
      if (_topics.containsKey(topic)) {
        _topics.remove(topic);
        await _fileSystem.write(_fileName, jsonEncode(_topics));
      }
      return 'OK';
    },
  );

  /// A helper method to generate a scoped description for tool functions.
  ///
  /// - [description]: The base description of the tool.
  ///
  /// Returns a string with the description, including the root path and
  /// an optional scope.
  String _scoped(String description) =>
      scope.isEmpty ? '$description.' : '$description; **scope: $scope**. ';
}
