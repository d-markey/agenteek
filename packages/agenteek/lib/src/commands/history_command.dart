import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../agents/agent.dart';
import '../utils/debug.dart';
import 'command.dart';

class HistoryCommand extends Command {
  const HistoryCommand() : output = null;

  HistoryCommand.to(this.output);

  final Sink<String>? output;

  @override
  String get name => 'history';

  @override
  String get description => 'Show the full conversation history.';

  @override
  Null handle(Agent agent, List<String> args) {
    final sb = StringBuffer();
    sb.writeln('Full conversation history:');
    sb.writeln('---');
    for (var message in agent.history.where(
      (m) => m.role != dartantic.ChatMessageRole.system,
    )) {
      sb.writeln(message.dump());
    }
    sb.writeln('---');
    (output?.add ?? print)(sb.toString());
    return null;
  }
}
