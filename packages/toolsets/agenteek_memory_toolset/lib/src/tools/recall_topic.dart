import 'package:agenteek/agenteek.dart';

import '../memory_toolset.dart';
import '_json_arguments.dart';

/// A tool that recalls a topic from memory.
Tool recallTopicTool(MemoryToolSet toolset) => Tool(
  name: toolset.buildToolName('recall_topic'),
  description: 'Loads information related to a topic from memory',
  inputSchema: RecallTopicArgs.schema,
  onCall: (args) => _recallTopic(toolset, RecallTopicArgs(args)),
);

Future<ToolSuccess<String>> _recallTopic(
  MemoryToolSet toolset,
  RecallTopicArgs args,
) async {
  final topics = await toolset.sync();
  final info = topics[args.topic]?.trim() ?? '';
  return ToolSuccess(info.isEmpty ? 'Unknown topic.' : info);
}
