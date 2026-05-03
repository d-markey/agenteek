import 'package:agenteek/agenteek.dart';
import '../memory_toolset.dart';

/// A tool that recalls a topic from memory.
Tool recallTopicTool(MemoryToolSet toolset) => Tool(
  name: toolset.buildToolName('recall_topic'),
  description: 'Loads information related to a topic from memory',
  inputSchema: z.object(
    {'topic': z.string('Topic to recall')},
    required: ['topic'],
  ),
  onCall: (args) => _recallTopic(toolset, args),
);

Future<ToolOutcome<String>> _recallTopic(MemoryToolSet toolset, Json args) async {
  final topic = args.getString('topic').trim().toLowerCase();
  if (topic.isEmpty) throw Exception('The topic argument cannot be empty.');
  
  final topics = await toolset.sync();
  final info = topics[topic];
  
  if (info != null) return ToolSuccess(info);
  return ToolSuccess('Unknown topic.');
}
