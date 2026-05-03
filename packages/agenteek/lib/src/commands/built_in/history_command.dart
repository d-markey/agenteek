import '../../agents/agent.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../../utils/debug.dart';
import '../command.dart';

class HistoryCommand extends Command {
  const HistoryCommand() : output = null;

  HistoryCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'history';

  @override
  String get description => 'Show the full conversation history.';

  @override
  Null handle(Agent agent, List<String> args) {
    try {
      final writeln = output?.writeln ?? print;
      if (agent.messages.isEmpty) {
        writeln('No history.');
        return;
      }

      writeln('### Full conversation history:');
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
