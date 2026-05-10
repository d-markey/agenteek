import '../../agents/agent.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../../utils/debug.dart' as dbg;
import '../command.dart';

class SystemMessagesCommand extends Command {
  const SystemMessagesCommand() : output = null;

  SystemMessagesCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'system';

  @override
  String get description => 'Show system messages.';

  @override
  Null handle(Agent agent, List<String> args) {
    try {
      final writeln = output?.writeln ?? print;
      if (agent.systemMessages.isEmpty) {
        writeln('**No system messages**');
        return;
      }

      writeln('### System Messages:');
      writeln('');
      writeln(agent.systemMessages.map(($) => $.dump()).join('\n'));
    } finally {
      if (output is NestedOutputSink) {
        (output as NestedOutputSink).close();
      }
    }
  }
}
