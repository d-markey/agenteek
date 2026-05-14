import 'package:agenteek/agenteek.dart';
import 'package:agenteek_team/src/toolsets/team/team_toolset.dart';

import '_json_arguments.dart';

/// Sends a prompt to this tool's agent.
Tool<String> sendMessageTool(TeamToolSet teamToolSet) => Tool(
  name: 'team.send_message',
  description:
      'Send a message (prompt) to an AI Agent; '
      'returns the response from the Agent.',
  inputSchema: SendMessageArgs.schema,
  onCall: (args) => _sendMessage(teamToolSet, SendMessageArgs(args)),
);

Future<ToolSuccess<String>> _sendMessage(
  TeamToolSet teamToolSet,
  SendMessageArgs args,
) async {
  final member = teamToolSet.members[args.agent];
  if (member == null) throw 'Unknown agent "${args.agent}"';
  member.agentSink?.add(args.prompt);
  final fullResponse = StringBuffer();
  try {
    await for (var output in member.agent.invoke(args.prompt)) {
      member.instructorSink?.add(output);
      fullResponse.write(output);
    }
  } catch (ex) {
    fullResponse.writeln();
    fullResponse.writeln(
      'Work suspended because of an error: $ex.\n'
      '\n'
      'Please advise or send `Resume work` to continue.',
    );
  }
  return ToolSuccess(fullResponse.toString());
}
