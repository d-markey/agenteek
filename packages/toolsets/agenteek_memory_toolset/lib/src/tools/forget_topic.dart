import 'dart:convert';
import 'package:agenteek/agenteek.dart';
import '../memory_toolset.dart';

/// A tool that forgets information about a topic.
Tool forgetTopicTool(MemoryToolSet toolset) => Tool(
  name: toolset.buildToolName('forget_topic'),
  description: 'Forget information about a topic',
  inputSchema: _inputSchema,
  onCall: (args) => _forgetTopic(toolset, args),
);

Future<ToolSuccess<String>> _forgetTopic(
  MemoryToolSet toolset,
  Json args,
) async {
  final topic = args.getString('topic').trim().toLowerCase();
  if (topic.isEmpty) throw 'Missing topic.';

  await toolset.sync();

  if (toolset.topics.containsKey(topic)) {
    toolset.topics.remove(topic);
    await toolset.fileSystem.write(
      toolset.fileName,
      jsonEncode(toolset.topics),
    );
  }

  return ToolSuccess.ok;
}

final _inputSchema = Z.object(
  properties: {'topic': Z.string(description: 'Topic to forget')},
  required: ['topic'],
);
