import 'package:agenteek/agenteek.dart';

import '../agenteek_team.dart';
import 'toolsets/team/team_toolset.dart';

// builds the team based on the provided configuration
Map<String, Agent> buildTeam(
  List<AgentConf> teamConf, {
  required Secrets secrets,
  PromptCallback? getUserInput,
  required OutputSink Function(String) outputCallbackBuilder,
  required OutputSink Function({
    required String from,
    required String to,
    required String color,
  })
  a2aSinkBuilder,
}) {
  final agents = <String, Agent>{};

  final interactive = (getUserInput != null);
  final rootAgentConf = teamConf.where((a) => a.instructor.isEmpty).single;
  final rootAgentName = rootAgentConf.displayName;

  for (var conf in teamConf) {
    final toolSet = ToolSet.combined(conf.toolSets);

    final agentName = '${conf.displayName} (${conf.role})';
    final chatManager = InMemoryConversationManager();
    final modelOutput = outputCallbackBuilder(agentName);

    final agent = (interactive && conf.displayName == rootAgentName)
        ? InteractiveAgent(
            conf.modelInfo,
            displayName: agentName,
            role: conf.role,
            conversationManager: chatManager,
            modelOutput: modelOutput,
            prompt: getUserInput,
            toolSet: toolSet,
          )
        : Agent(
            conf.modelInfo,
            conversationManager: chatManager,
            displayName: agentName,
            role: conf.role,
            modelOutput: modelOutput,
            toolSet: toolSet,
          );

    agents[conf.displayName] = agent;

    if (conf.instructor.isNotEmpty) {
      final instructorConf = teamConf
          .where(($) => $.displayName == conf.instructor)
          .single;
      instructorConf.registerTeamMember(agentName);
    }
  }

  final teamToolsets = <Agent, TeamToolSet>{};

  for (var conf in teamConf) {
    final agent = agents[conf.displayName]!;

    conf.prepareInstructions();
    agent.systemInstructions = conf.instructions;

    if (conf.instructor.isNotEmpty) {
      final instructor = agents[conf.instructor]!;
      final agentSink = a2aSinkBuilder(
        from: instructor.displayName,
        to: conf.displayName,
        color: '44', // blue background
      );
      final instructorSink = a2aSinkBuilder(
        from: conf.displayName,
        to: instructor.displayName,
        color: '45', // magenta background
      );
      teamToolsets
          .putIfAbsent(instructor, () {
            final teamToolSet = TeamToolSet();
            instructor.registerToolSet(teamToolSet);
            return teamToolSet;
          })
          .registerTeamMember(
            agent,
            agentSink: agentSink,
            instructorSink: instructorSink,
          );
    }
  }

  agents[rootAgentName]!.startNewConversation();

  return agents;
}
