import '../agents/agent.dart';
import 'command.dart';

class ToolsCommand extends Command {
  const ToolsCommand() : output = null;

  ToolsCommand.to(this.output);

  final Sink<String>? output;

  @override
  String get name => 'tools';

  @override
  String get description => 'List available tools for the current agent.';

  @override
  Null handle(Agent agent, List<String> args) {
    (output?.add ?? print)(
      agent.toolNames.isEmpty
          ? 'No available tools.'
          : 'Available tools: ${agent.toolNames.join(', ')}.',
    );
    return null;
  }
}
