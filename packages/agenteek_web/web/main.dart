import 'package:agenteek/agenteek.dart';
import 'package:dartantic_ai/dartantic_ai.dart';

import '_agent_ui.dart';
import 'config/config_store.dart';
import 'config/toolsets.dart';

void main() async {
  final conversationManager = InMemoryConversationManager();
  final agentUi = AgentUI(conversationManager);

  final nestedSystemOutput = agentUi.systemOutput.nested;
  final commands = CommandRegistry();
  commands.register(QuitCommand(callback: agentUi.quit));
  commands.register(HelpCommand.to(nestedSystemOutput));
  commands.register(HistoryCommand.to(nestedSystemOutput));
  commands.register(SummarizeCommand.to(nestedSystemOutput));
  commands.register(CompactCommand.to(nestedSystemOutput));
  commands.register(SystemPromptCommand.to(nestedSystemOutput));
  commands.register(ToolsCommand.to(nestedSystemOutput));
  commands.register(ClearCommand.to(nestedSystemOutput));

  InteractiveAgent? agent;
  var start = true;

  final agentSub = agentUi.agentConfiguration.listen(
    (webConf) async {
      if (webConf == null) {
        if (agent == null) {
          agentUi.systemOutput.add(
            'Please click on "Configure Agent" to setup model info and tools.',
          );
        }
        return;
      }

      var curAgent = agent;
      if (curAgent != null) {
        curAgent.stopInteracting();
        await curAgent.dispose();
      }

      final agentConf = webConf.agentConfiguration;

      // initialize/re-initialize toolsets with new PAT if changed
      agentUi.systemOutput.add('Updating toolsets...');
      final toolSet = await initializeToolSets(
        ConfigStore.current,
        webConf.secrets,
      );
      agentUi.systemOutput.add('Toolsets are ready.');

      agent = curAgent = InteractiveAgent(
        agentConf.modelInfo,
        conversationManager: conversationManager,
        displayName: agentConf.displayName,
        prompt: agentUi.userInput,
        toolSet: toolSet,
        modelOutput: agentUi.modelOutput,
        streamingOutput: agentUi.modelStreamOutput,
        streamingThinking: agentUi.modelThinkingStreamOutput,
        onError: (error, [st]) async {
          agentUi.systemOutput.add('Error: $error');
          return 'I encountered an issue. '
              'Please try again or rephrase your request.';
        },
        onNewConversation: () {
          agentUi.clearMessages();
          agentUi.modelOutput.add('Hello, how can I help you today?');
        },
        commandRegistry: commands,
      );

      agentUi.systemOutput.add('Model info: ${agentConf.modelInfo}');

      if (start) {
        start = false;
        await curAgent.startNewConversation();
      }
      curAgent.interactWithUser(tokenFactory: agentUi.createToken);
    },
    onError: (ex, st) {
      agentUi.systemOutput.add('Error: $ex');
    },
    cancelOnError: false,
  );

  // initialize agent on startup
  await agentUi.initializeAgent();

  await agentSub.asFuture();

  agentUi.shutdown();
  agentUi.modelOutput.add('Goodbye!');
  agentUi.systemOutput.add('Closing chat...');

  await agent?.dispose();
  agentUi.systemOutput.add(
    'Chat closed. '
    'Reload the page to start a new session.',
  );
}
