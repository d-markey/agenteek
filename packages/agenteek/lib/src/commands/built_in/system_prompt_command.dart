import 'package:agenteek/agenteek_dbg.dart' as dbg;

import '../../agents/agent.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../command.dart';

class SystemPromptCommand extends Command {
  const SystemPromptCommand() : output = null;

  SystemPromptCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'system';

  @override
  String get description => 'Show the current system prompt.';

  @override
  List<String> get aliases => const ['system-prompt', 'sys'];

  @override
  Null handle(Agent agent, List<String> args) {
    try {
      final writeln = output?.writeln ?? print;
      if (agent.systemPrompts.isEmpty) {
        writeln('**No system prompt**');
        return;
      }

      writeln('### System Prompt:');
      writeln('');
      writeln(agent.systemPrompts.map(($) => $.dump()).join('\n'));
    } finally {
      if (output is NestedOutputSink) {
        (output as NestedOutputSink).close();
      }
    }
  }
}
