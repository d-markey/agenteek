import 'package:agenteek/agenteek.dart';

import '../team_toolset.dart';
import '_json_arguments.dart';

/// Clears the conversation history of an agent (starts a new conversation).
Tool<String> clearHistoryTool(TeamToolSet teamToolSet) => Tool(
  name: 'team.clear_history',
  description:
      'Clear the context window (conversation history) of an AI Agent '
      'has same effect as starting a new conversation.',
  inputSchema: ClearHistoryArgs.schema,
  onCall: (args) => _clearHistory(teamToolSet, ClearHistoryArgs(args)),
);

Future<ToolSuccess<String>> _clearHistory(
  TeamToolSet teamToolSet,
  ClearHistoryArgs args,
) async {
  final member = teamToolSet.members[args.agent];
  if (member == null) throw 'Unknown agent "${args.agent}"';
  member.agentSink?.add('(clear history)');
  await member.agent.startNewConversation();
  return ToolSuccess.ok;
}
