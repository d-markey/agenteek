import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';
import 'package:better_future/better_future.dart';

import 'mcp_arithmetic_client.dart';
import 'user_command_handler.dart';

void main() async {
  Log.enable();
  late Secrets secrets;
  late McpToolSet mcpTools;

  final dir = File(Platform.script.toFilePath()).parent;

  // get api key and initialize MCP toolset
  await BetterFuture.wait({
    'secrets': () async {
      final file = await FileLocator.find(dir, '.secret.keys');
      if (file != null) {
        secrets = await Secrets.load(file.path);
      } else {
        secrets = InMemorySecrets(const {});
      }
    },
    'tools': () async {
      final mcp = await initializeArithmeticMcpServerAndClient();
      mcpTools = McpToolSet('math', 'math', mcp.client, mcp.connection);
      await mcpTools.initialize();
    },
  });

  final agentConf = AgentConfiguration(
    modelInfo: 'mistral:devstral-medium-latest',
    apiKeyName: 'mistral-api-key',
    displayName: 'Math Student',
    secrets: secrets,
  );

  final conversationManager = InMemoryConversationManager();

  final agent = InteractiveAgent(
    agentConf.modelInfo,
    conversationManager: conversationManager,
    displayName: agentConf.displayName,
    prompt: () {
      stdout.write('\x1B[94mYou\x1B[0m: ');
      return stdin.readLineSync()?.trim() ?? '';
    },
    modelOutput: AgentSink(agentConf.displayName),
    toolSet: mcpTools,
  );

  await agent.startNewConversation(
    systemPrompt:
        'Follow mathematical operator precedence, i.e. multiplications before additions. '
        'To check if a number is prime, check remainders of divisions by numbers greater than 1 and less than half the checked number: if all remainders are positive, it means the number is prime. '
        'When checking for primality: as soon as a remainder is zero, no further checks are necessary and the number is prime. '
        'When possible, reuse previous calculations and tool results and indicate which results were reused. '
        'Note that "a - b" (subtracting b from a) is equivalent to "a + -b". ',
  );

  print(
    '${agent.displayName} Agent is running with model ${agent.chatModelName}.',
  );
  await agent.interactWithUser(handleUserCommand: commandHandler);

  // clean up
  mcpTools.dispose();
}

class AgentSink implements OutputSink {
  AgentSink(this.name);

  final String name;

  @override
  void add(String data) {
    for (var line in data.split('\n')) {
      stdout.writeln('\x1B[94m$name\x1B[0m: $line');
    }
  }

  @override
  void writeln(String message) => add(message);

  @override
  void close() {}
}
