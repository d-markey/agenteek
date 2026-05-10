import '../../agents/agent.dart';
import '../../output_sinks/nested_output_sink.dart';
import '../../output_sinks/output_sink.dart';
import '../command.dart';

class ListModelsCommand extends Command {
  const ListModelsCommand() : output = null;

  ListModelsCommand.to(this.output);

  final OutputSink? output;

  @override
  String get name => 'models';

  @override
  String get description =>
      'List models from provider configured for this Agent.';

  @override
  Future<Null> handle(Agent agent, List<String> args) async {
    try {
      final writeln = output?.writeln ?? print;

      writeln('Provider: ${agent.provider.name}, model ${agent.model}');
      await for (var model in agent.provider.listModels()) {
        writeln('* ${model.name}: ${model.displayName} - ${model.description}');
      }
    } finally {
      if (output is NestedOutputSink) {
        (output as NestedOutputSink).close();
      }
    }
  }
}
