import '../../agents/agent.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../command.dart';

class ToolsCommand extends Command {
  const ToolsCommand() : output = null;

  ToolsCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'tools';

  @override
  String get description => 'List available tools for the current agent.';

  @override
  Null handle(Agent agent, List<String> args) {
    try {
      final writeln = output?.writeln ?? print;
      if (agent.toolNames.isEmpty) {
        writeln('**No available tools**');
        return;
      }

      final toolsets = agent.toolNames
          .map((t) => t.split('_').first)
          .toSet()
          .toList();
      toolsets.sort();

      for (var toolset in toolsets) {
        final tools = agent.toolNames
            .where((t) => t.startsWith('${toolset}_') || t == toolset)
            .toList();
        tools.sort();
        writeln(
          '* ${tools.length} tools in **"$toolset" toolset**: ${tools.join(', ')}',
        );
      }
    } finally {
      if (output is NestedOutputSink) {
        (output as NestedOutputSink).close();
      }
    }
  }
}
