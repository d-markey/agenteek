import 'package:agenteek/agenteek.dart';

class WebAgentConfig {
  WebAgentConfig({required this.agentConfiguration, required this.secrets});

  final AgentConfiguration agentConfiguration;
  final Secrets secrets;
}
