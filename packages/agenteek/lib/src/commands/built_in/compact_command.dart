import '../../agents/agent.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../../utils/debug.dart';
import '../command.dart';

class CompactCommand extends Command {
  const CompactCommand() : output = null;

  CompactCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'compact';

  @override
  String get description => 'Compact the current conversation history.';

  @override
  Null handle(Agent agent, List<String> args) {
    try {
      final writeln = output?.writeln ?? print;
      if (agent.messages.isEmpty) {
        writeln('No messages to compact.');
        return;
      }

      writeln('### Compacting conversation:');
      for (var message in agent.messages) {
        writeln(message.dump());
      }

      agent.compactHistory();

      writeln('### Compacted conversation:');
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
