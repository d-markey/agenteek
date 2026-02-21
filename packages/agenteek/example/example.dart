import 'dart:io';
import 'package:agenteek/agenteek_dbg.dart' as dbg;
import 'package:agenteek/agenteek.dart';

void main() async {
  dbg.trace = (_) {};

  // 1. Setup secrets (manual for web or loaded for CLI)
  // In a real app, you'd load this from an environment variable or secret store.
  final secrets = InMemorySecrets({
    'openai_key': Platform.environment['OPENAI_API_KEY'] ?? 'your-key-here',
  });

  // 2. Define your agent configuration
  // This automatically registers a custom provider alias with your API key
  final config = AgentConfiguration(
    modelInfo: 'openai:gpt-4o',
    apiKeyName: 'openai_key',
    displayName: 'Agenteek Assistant',
    secrets: secrets,
  );

  final conversationManager = InMemoryConversationManager();

  // 3. Create the interactive agent
  final agent = InteractiveAgent(
    config.modelInfo, // Uses the automatically created custom provider alias
    displayName: config.displayName,
    conversationManager: conversationManager,
    prompt: () {
      stdout.write('\nYOU > ');
      return stdin.readLineSync() ?? '';
    },
    // Use the model output sink to print agent responses to console
    modelOutput: ConsoleSink(config.displayName),
    // Use error handling with recovery
    onError: (error, [st]) async {
      print('\n[SYSTEM ERROR]: $error');
      return "I'm sorry, I'm having trouble processing that right now. Could you try again?";
    },
    onNewConversation: () {
      print('--- Starting a new conversation with ${config.displayName} ---');
    },
  );

  // Start the interaction loop
  print(
    'Welcome to Agenteek! Type your message to start chatting (or /quit to exit).',
  );

  await agent.startNewConversation();
  await agent.interactWithUser();

  print('\nGoodbye!');
}

/// A simple sink to print agent responses to the console.
/// We use 'implements' because Sink is an interface class.
class ConsoleSink implements Sink<String> {
  final String name;
  ConsoleSink(this.name);

  @override
  void add(String data) {
    if (data.trim().isNotEmpty) {
      stdout.write('\n$name > $data\n');
    }
  }

  @override
  void close() {}
}
