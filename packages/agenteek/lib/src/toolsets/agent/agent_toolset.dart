import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../../agents/agent.dart';
import '../../utils/null_sink.dart';
import '../../utils/types.dart';
import '../../utils/zod.dart';
import '../toolset.dart';

/// A `ToolSet` that provides tools for interacting with a specific AI agent.
class AgentToolSet extends ToolSet {
  /// Initializes a new instance of the `AgentToolSet`.
  ///
  /// This constructor sets up the toolset for a specific agent, registering
  /// tools for sending prompts and managing conversation history.
  ///
  /// - [id]: The unique identifier for the agent (used in tool names like ${id}_prompt).
  /// - [_agent]: The actual `Agent` instance this toolset wraps.
  /// - [modelInput]: An optional callback to intercept and process the model's input.
  AgentToolSet(this.id, this._agent, {this.modelInput = const NullSink()}) {
    register(_promptSpec);
    register(_clearHistorySpec);
  }

  /// The unique identifier for the agent.
  final String id;

  /// The `Agent` instance this toolset wraps.
  final Agent _agent;

  /// An optional callback to intercept and process the model's input.
  final Sink<String> modelInput;

  /// Returns the name of the agent.
  String get agentName => _agent.name;

  /// Sends a prompt to this tool's agent.
  late final _promptSpec = dartantic.Tool(
    name: '${id}_prompt',
    description:
        'Sends a prompt to agent $agentName (agent ID: $id). '
        'Returns the output from the agent.',
    inputSchema: z.object(
      {'message': z.string('The prompt to submit to the agent.')},
      required: ['message'],
    ),

    onCall: (args) async {
      args as Json;
      final prompt = args['message'] as String;
      modelInput.add(prompt);
      final response = await _agent.invoke(prompt);
      _agent.modelOutput.add(response);
      return response;
    },
  );

  /// Clears the conversation history of this tool's agent (starts a new conversation).
  late final dartantic.Tool _clearHistorySpec = dartantic.Tool(
    name: '${id}_clear_history',
    description:
        'Clears the chat history of agent $agentName (agent ID: $id). '
        'Has same effect as starting a new conversation. '
        'Returns the conversation id.',
    onCall: (args) async {
      args as Map;
      modelInput.add('`${id}_clear_history`');
      final chatId = await _agent.startNewConversation();
      return {'chatId': chatId};
    },
  );
}
