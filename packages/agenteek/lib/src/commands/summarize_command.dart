import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../agents/agent.dart';
import '../utils/debug.dart';
import 'command.dart';

class SummarizeCommand extends Command {
  const SummarizeCommand() : output = null;

  SummarizeCommand.to(this.output);

  final Sink<String>? output;

  @override
  FutureOr<Null> handle(Agent agent) async {
    final sb = StringBuffer();
    sb.writeln('Summary for conversation:');
    sb.writeln('---');
    for (var message in agent.messages) {
      sb.writeln(message.dump());
    }
    sb.writeln('---');
    (output?.add ?? print)(sb.toString());

    await agent.summarizeConversation();

    sb.clear();
    sb.writeln('Summarized conversation:');
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
