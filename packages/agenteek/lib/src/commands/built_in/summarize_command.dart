import 'dart:async';

import '../../agents/agent.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../../utils/debug.dart';
import '../command.dart';

class SummarizeCommand extends Command {
  const SummarizeCommand() : output = null;

  SummarizeCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'summarize';

  @override
  String get description => 'Summarize the current conversation history.';

  @override
  List<String> get aliases => const ['summary'];

  @override
  Future<Null> handle(Agent agent, List<String> args) async {
    try {
      final writeln = output?.writeln ?? print;
      if (agent.messages.isEmpty) {
        writeln('No messages to summarize.');
        return;
      }

      writeln('### Summary for conversation:');
      for (var message in agent.messages) {
        writeln(message.dump());
      }

      await agent.summarizeConversation();

      writeln('### Summarized conversation:');
      for (var message in agent.history.where((m) => m.role != .system)) {
        writeln(message.dump());
      }
    } finally {
      if (output is NestedOutputSink) {
        (output as NestedOutputSink).close();
      }
    }
  }
}
