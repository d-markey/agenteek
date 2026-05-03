import 'dart:async';

import '../../agents/agent.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../command.dart';

class ClearCommand extends Command {
  const ClearCommand() : output = null;

  ClearCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'clear';

  @override
  List<String> get aliases => const ['new'];

  @override
  String get description =>
      'Clear the current conversation history and start a new one.';

  @override
  Future<Null> handle(Agent agent, List<String> args) async {
    try {
      final writeln = output?.writeln ?? print;
      await agent.startNewConversation();
      writeln('New converstation started.');
    } finally {
      if (output is NestedOutputSink) {
        (output as NestedOutputSink).close();
      }
    }
  }
}
