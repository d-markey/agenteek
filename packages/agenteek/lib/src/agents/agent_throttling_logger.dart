import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import 'agent_logger.dart';

class AgentThrottlingLogger extends AgentLogger {
  AgentThrottlingLogger(super.agent, Duration throttlingDelay)
    : _throttlingMs = throttlingDelay.inMilliseconds;

  final int _throttlingMs;

  final sw = Stopwatch()..start();

  @override
  void logUsage(dartantic.ChatResult result) {
    if (result.usage == null) return;

    super.logUsage(result);

    // ensure _throttlingMs delay between logs
    while (sw.elapsedMilliseconds < _throttlingMs) {
      for (var i = 0; i < 5000; i++) {
        // throttle
      }
    }
    sw.reset();
  }
}
