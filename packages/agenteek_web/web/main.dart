import 'package:agenteek/agenteek.dart';

import '_agent_ui.dart';
import 'config/config_store.dart';
import '_toolsets.dart';

void main() async {
  final memory = MemoryFileSystem();
  final conversationManager = PersistentConversationManager(memory);
  final agentUi = AgentUI(conversationManager);

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
        streamingThinkingOutput: agentUi.modelThinkingStreamOutput,
        onError: (error, [st]) async {
          agentUi.systemOutput.add('Error: $error');
          return 'I encountered an issue. '
              'Please try again or rephrase your request.';
        },
        onNewConversation: () {
          agentUi.clearMessages();
          agentUi.modelOutput.add('Hello, how can I help you today?');
        },
      );

      agentUi.systemOutput.add('Model info: ${agentConf.modelInfo}');

      if (start) {
        start = false;
        await curAgent.startNewConversation();
      }
      curAgent.interactWithUser(
        handleUserCommand: agentUi.userCommandHandler,
        tokenFactory: agentUi.createToken,
      );
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
