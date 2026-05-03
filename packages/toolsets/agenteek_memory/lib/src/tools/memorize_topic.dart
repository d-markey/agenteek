import 'dart:convert';
import 'package:agenteek/agenteek.dart';
import '../memory_toolset.dart';

/// A tool that remembers information about a topic.
Tool memorizeTopicTool(MemoryToolSet toolset) => Tool<String>(
  name: toolset.buildToolName('memorize_topic'),
  description:
      'Associate information to a topic in memory; if the topic is already present in memory, the provided information is concatenated with the existing information',
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
  onCall: (args) => _memorizeTopic(toolset, args),
);

Future<ToolOutcome<String>> _memorizeTopic(
  MemoryToolSet toolset,
  Json args,
) async {
  // load args
  final topic = args.getString('topic').trim().toLowerCase();
  var information = args.getString('information').trim();
  final mode = args.getString('mode').trim().toLowerCase();

  if (topic.isEmpty) throw Exception('ERROR: missing topic.');
  if (information.isEmpty) throw Exception('ERROR: missing information.');
  if (mode.isEmpty || (mode != 'set' && mode != 'update')) {
    throw Exception('ERROR: invalid mode: "$mode".');
  }

  await toolset.sync();

  if (mode == 'update') {
    final existing = toolset.topics[topic] ?? '';
    if (existing.isNotEmpty) {
      information = '$existing\n\n$information';
    }
  }

  toolset.topics[topic] = information;
  await toolset.fileSystem.write(toolset.fileName, jsonEncode(toolset.topics));

  return ToolSuccess.ok;
}
