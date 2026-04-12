import '../agents/agent.dart';
import '../agents/agent_interactive.dart';
import 'command.dart';

class QuitCommand extends Command {
  const QuitCommand({void Function()? callback}) : _callback = callback;

  final void Function()? _callback;

  @override
  String get name => 'quit';

  @override
  String get description => 'Stop interacting and quit the session.';

  @override
  List<String> get aliases => const ['exit', 'q'];

  @override
  Null handle(Agent agent, List<String> args) {
    if (agent is InteractiveAgent) {
      agent.stopInteracting();
      _callback?.call();
    }
    return null;
  }
}
