import 'dart:async';

import '../agents/agent.dart';
import '../agents/agent_interactive.dart';
import 'command.dart';

/// A command that displays the available commands to the user.
class HelpCommand extends Command {
  const HelpCommand() : output = null;

  HelpCommand.to(this.output);

  final Sink<String>? output;

  @override
  String get name => 'help';

  @override
  String get description => 'Show this help message.';

  @override
  List<String> get aliases => const ['?', 'h'];

  @override
  FutureOr<String?> handle(Agent agent, List<String> args) {
    if (agent is! InteractiveAgent) {
      return 'Help only available for Interactive agents.';
    }

    final sb = StringBuffer();
    sb.writeln('Help: List of available commands:');
    sb.writeln('---');

    final commands = agent.commandRegistry.all.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final cmd in commands) {
      sb.write('  /${cmd.name}');
      if (cmd.aliases.isNotEmpty) {
        sb.write(' (aliases: ${cmd.aliases.map((a) => '/$a').join(', ')})');
      }
      sb.writeln(': ${cmd.description}');
    }
    sb.writeln('---');

    final message = sb.toString();
    (output?.add ?? print)(message);

    return null;
  }
}
