import 'dart:async';

import '../agents/agent.dart';

abstract class Command {
  const Command();

  FutureOr<String?> handle(Agent agent);
}
