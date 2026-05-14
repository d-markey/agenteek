import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import '../memory_toolset.dart';
import '_json_arguments.dart';

/// A tool that forgets information about a topic.
Tool<String> forgetTopicTool(MemoryToolSet toolset) => Tool(
  name: toolset.buildToolName('forget_topic'),
  description: 'Forget information about a topic',
  inputSchema: ForgetTopicArgs.schema,
  onCall: (args) => _forgetTopic(toolset, ForgetTopicArgs(args)),
);

Future<ToolSuccess<String>> _forgetTopic(
  MemoryToolSet toolset,
  ForgetTopicArgs args,
) async {
  await toolset.sync();

  if (toolset.topics.containsKey(args.topic)) {
    toolset.topics.remove(args.topic);
    await toolset.fileSystem.write(
      toolset.fileName,
      jsonEncode(toolset.topics),
    );
  }

  return ToolSuccess.ok;
}
