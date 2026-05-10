import 'package:agenteek/agenteek.dart';

import '../memory_toolset.dart';

/// A tool that lists all topics held in memory.
Tool listTopicsTool(MemoryToolSet toolset) => Tool(
  name: toolset.buildToolName('list_topics'),
  description: 'List all topics held in memory',
  onCall: (_) => _listTopics(toolset),
);

Future<ToolSuccess<Json>> _listTopics(MemoryToolSet toolset) async {
  final topics = await toolset.sync();
  return ToolSuccess<Json>({'topics': topics.keys.toList()});
}
