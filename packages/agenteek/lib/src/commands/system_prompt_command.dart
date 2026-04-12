import '../agents/agent.dart';
import 'command.dart';

class SystemPromptCommand extends Command {
  const SystemPromptCommand() : output = null;

  SystemPromptCommand.to(this.output);

  final Sink<String>? output;

  @override
  String get name => 'system';

  @override
  String get description => 'Show the current system prompt.';

  @override
  Null handle(Agent agent, List<String> args) {
    (output?.add ?? print)(
      'System Prompt:\n---\n${agent.systemPrompt}\n---',
    );
    return null;
  }
}
