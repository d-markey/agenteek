import 'package:agenteek/agenteek.dart';

import '_chatbot_ui.dart';
import '_toolsets.dart';

void main() async {
  final conversationManager = InMemoryConversationManager();

  final chatbot = ChatbotUI(conversationManager);

  final imagingApiKey = await chatbot.getImagingApiKey();

  // initialize
  chatbot.systemOutput.add(
    'Toolsets are initializing... '
    'please provide model info and API key.',
  );
  final toolSet = await initializeToolSets(imagingApiKey);
  chatbot.systemOutput.add('Toolsets are ready.');

  InteractiveAgent? agent;
  var start = true;

  await for (var agentConf in chatbot.agentConfiguration) {
    if (agent != null) {
      agent.stopInteracting();
      await agent.dispose();
    }

    agent = InteractiveAgent(
      agentConf.modelInfo,
      conversationManager: conversationManager,
      displayName: agentConf.displayName,
      prompt: chatbot.userInput,
      toolSet: toolSet,
      modelOutput: chatbot.modelOutput,
      onError: (error, [st]) async {
        chatbot.systemOutput.add('Error: $error');
        return 'I encountered an issue. '
            'Please try again or rephrase your request.';
      },
      onNewConversation: () {
        chatbot.clearMessages();
        chatbot.modelOutput.add('Hello, how can I help you today?');
      },
    );

    chatbot.systemOutput.add('Model info: ${agentConf.modelInfo}');

    if (start) {
      start = false;
      await agent.startNewConversation();
    }
    agent.interactWithUser(chatbot.userCommandHandler);
  }

  chatbot.shutdown();
  chatbot.modelOutput.add('Goodbye!');
  chatbot.systemOutput.add('Closing chat...');

  await agent?.dispose();
  chatbot.systemOutput.add(
    'Chat closed. '
    'Reload the page to start a new session.',
  );
}
