import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg show trace;

import 'agent_conf.dart';

// builds the team based on the provided configuration
Map<String, Agent> buildTeam(
  List<AgentConf> teamConf, {
  required Secrets secrets,
  PromptCallback? getUserInput,
  required Sink<String> Function(String) outputCallbackBuilder,
  required Sink<String> Function(String, String) inputCallbackBuilder,
}) {
  final agents = <String, Agent>{};

  final interactive = (getUserInput != null);
  final rootAgentName = teamConf
      .where((a) => a.instructor.isEmpty)
      .single
      .displayName;

  for (var conf in teamConf) {
    final toolSet = ToolSet.combined(conf.toolSets);

    final agentName = '${conf.displayName} (${conf.role})';
    final chatManager = InMemoryConversationManager();
    final modelOutput = outputCallbackBuilder(agentName);

    final agent = (interactive && conf.displayName == rootAgentName)
        ? InteractiveAgent(
            conf.modelInfo,
            conversationManager: chatManager,
            systemPrompt: conf.instructions,
            modelOutput: modelOutput,
            prompt: getUserInput,
            toolSet: toolSet,
          )
        : Agent(
            conf.modelInfo,
            conversationManager: chatManager,
            displayName: agentName,
            systemPrompt: conf.instructions,
            modelOutput: modelOutput,
            toolSet: toolSet,
          );

    agents[conf.displayName] = agent;

    dbg.trace('$agentName is running with model ${conf.displayName}.');
    chatLogger.append('[$agentName] Running with model ${conf.displayName}.');
    modelLogger.append(
      '[$agentName] Running with model ${conf.displayName}\n[$agentName] Available toolset:\n****\n${agent.toolSet.tools.join('\n')}\n****',
    );

    if (conf.instructor.isNotEmpty) {
      final instructorConf = teamConf
          .where(($) => $.displayName == conf.instructor)
          .single;
      instructorConf.registerTeamMember(agentName);
      final modelInput = inputCallbackBuilder(
        instructorConf.displayName,
        conf.displayName,
      );
      instructorConf.registerToolSet(
        AgentToolSet(conf.role, agent, modelInput: modelInput),
      );
    }
  }

  for (var conf in teamConf) {
    conf.prepareInstructions();
    chatLogger.append(
      'Instructions for ${conf.displayName} (${conf.role}):\n****\n${conf.instructions}\n****',
    );
  }

  return agents;
}
