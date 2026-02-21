import '../agents/agent.dart';
import 'command.dart';

class SystemPromptCommand extends Command {
  const SystemPromptCommand() : output = null;

  SystemPromptCommand.to(this.output);

  final Sink<String>? output;

  @override
  Null handle(Agent agent) {
    (output?.add ?? print)(
      'System instruction:\n'
      '*****\n'
      '${agent.systemPrompt?.text ?? ''}\n'
      '******',
    );
    return null;
  }
}
