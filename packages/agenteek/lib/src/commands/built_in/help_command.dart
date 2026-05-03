import '../../agents/agent.dart';
import '../../agents/agent_interactive.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../command.dart';

/// A command that displays the available commands to the user.
class HelpCommand extends Command {
  const HelpCommand() : output = null;

  HelpCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'help';

  @override
  String get description => 'Show this help message.';

  @override
  List<String> get aliases => const ['?', 'h'];

  @override
  Null handle(Agent agent, List<String> args) {
    try {
      final writeln = output?.writeln ?? print;
      if (agent is! InteractiveAgent) {
        writeln('Help only available for Interactive agents.');
        return;
      }

      final commands = agent.commandRegistry.all.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      writeln('List of available commands:');
      final sb = StringBuffer();
      for (final cmd in commands) {
        sb.clear();
        sb.write('* /**${cmd.name}**');
        if (cmd.aliases.isNotEmpty) {
          sb.write(
            ' (aliases: ${cmd.aliases.map((a) => '/**$a**').join(', ')})',
          );
        }
        sb.write(': ${cmd.description}');
        writeln(sb.toString());
      }
    } finally {
      if (output is NestedOutputSink) {
        (output as NestedOutputSink).close();
      }
    }
  }
}
