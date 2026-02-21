import '../agents/agent.dart';
import '../agents/agent_interactive.dart';
import 'command.dart';

class QuitCommand extends Command {
  const QuitCommand({void Function()? callback}) : _callback = callback;

  final void Function()? _callback;

  @override
  Null handle(Agent agent) {
    if (agent is InteractiveAgent) {
      agent.stopInteracting();
      _callback?.call();
    }
    return null;
  }
}
