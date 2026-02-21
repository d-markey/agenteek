import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_cli/agenteek_cli.dart';
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
    'secretsFile': () => FileLocator.find(dir, '.secret.keys'),
    'secrets': ($) async {
      secrets = await InMemorySecrets.load($.secretsFile!.path);
    },
    'mcp': () => initializeArithmeticMcpServerAndClient(),
    'tools': ($) async {
      mcpTools = McpToolSet('math', 'math', $.mcp.client, $.mcp.connection);
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
    systemPrompt:
        'Follow mathematical operator precedence, i.e. multiplications before additions. '
        'To check if a number is prime, check remainders of divisions by numbers greater than 1 and less than half the checked number: if all remainders are positive, it means the number is prime. '
        'When checking for primality: as soon as a remainder is zero, no further checks are necessary and the number is prime. '
        'When possible, reuse previous calculations and tool results and indicate which results were reused. '
        'Note that "a - b" (subtracting b from a) is equivalent to "a + -b". ',
    prompt: () {
      stdout.write('\x1B[94mYou\x1B[0m: ');
      return stdin.readLineSync()?.trim() ?? '';
    },
    modelOutput: AgentSink(agentConf.displayName),
    toolSet: mcpTools,
  );

  await agent.startNewConversation();

  print(
    '${agent.name} Agent is running with model ${agent.agent.chatModelName}.',
  );
  await agent.interactWithUser(commandHandler);

  // clean up
  mcpTools.dispose();
}

class AgentSink implements Sink<String> {
  AgentSink(this.name);

  final String name;

  @override
  void add(String data) {
    for (var line in data.split('\n')) {
      stdout.writeln('\x1B[94m$name\x1B[0m: $line');
    }
  }

  @override
  void close() {}
}
