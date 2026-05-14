import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import '../memory_toolset.dart';
import '_json_arguments.dart';

/// A tool that remembers information about a topic.
Tool<String> memorizeTopicTool(MemoryToolSet toolset) => Tool<String>(
  name: toolset.buildToolName('memorize_topic'),
  description:
      'Associate information to a topic in memory; if the topic is already present in memory, the provided information is concatenated with the existing information',
  inputSchema: MemorizeTopicArgs.schema,
  onCall: (args) => _memorizeTopic(toolset, MemorizeTopicArgs(args)),
);

Future<ToolSuccess<String>> _memorizeTopic(
  MemoryToolSet toolset,
  MemorizeTopicArgs args,
) async {
  await toolset.sync();

  var information = args.information;
  if (args.mode == 'update') {
    final existing = toolset.topics[args.topic] ?? '';
    if (existing.isNotEmpty) {
      information = '$existing\n\n$information';
    }
  }

  toolset.topics[args.topic] = information;
  await toolset.fileSystem.write(toolset.fileName, jsonEncode(toolset.topics));

  return ToolSuccess.ok;
}
