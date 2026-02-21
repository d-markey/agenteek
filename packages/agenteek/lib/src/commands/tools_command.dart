import '../agents/agent.dart';
import 'command.dart';

class ToolsCommand extends Command {
  const ToolsCommand() : output = null;

  ToolsCommand.to(this.output);

  final Sink<String>? output;

  @override
  Null handle(Agent agent) {
    (output?.add ?? print)(
      agent.toolNames.isEmpty
          ? 'No available tools.'
          : 'Available tools: ${agent.toolNames.join(', ')}.',
    );
    return null;
  }
}
