import 'dart:async';

import '../agents/agent.dart';

abstract class Command {
  const Command();

  /// The name of the command (e.g., 'help' for '/help').
  String get name;

  /// A short description of the command for the help list.
  String get description;

  /// Optional aliases for the command (e.g., ['q'] for '/quit').
  List<String> get aliases => const [];

  /// Executes the command with the given [agent] and [args].
  FutureOr<String?> handle(Agent agent, List<String> args);
}
