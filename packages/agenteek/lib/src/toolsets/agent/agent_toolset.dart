import 'dart:async';

import '../../agents/agent.dart';
import '../../output_sinks/output_sink.dart';
import '../../utils/types.dart';
import '../../utils/zod.dart';
import '../prefix_mixin.dart';
import '../tool.dart';
import '../tool_outcome.dart';
import '../toolset.dart';

/// A `ToolSet` that provides tools for interacting with a specific AI agent.
class AgentToolSet extends ToolSet with Prefix {
  /// Initializes a new instance of the `AgentToolSet`.
  ///
  /// This constructor sets up the toolset for a specific agent, registering
  /// tools for sending prompts and managing conversation history.
  ///
  /// - [role]: The unique identifier for the agent (used in tool names like ${id}_prompt).
  /// - [_agent]: The actual `Agent` instance this toolset wraps.
  /// - [modelInput]: An optional callback to intercept and process the model's input.
  AgentToolSet(
    this._agent, {
    String? systemPrompt,
    this.modelInput = const NullOutputSink(),
  }) : _systemPrompt = systemPrompt {
    register(_sendMessageSpec);
    register(_clearHistorySpec);
    unawaited(_agent.startNewConversation(systemPrompt: _systemPrompt));
  }

  /// The `Agent` instance this toolset wraps.
  final Agent _agent;

  final String? _systemPrompt;

  /// An optional callback to intercept and process the model's input.
  final Sink<String> modelInput;

  @override
  String get prefix => _agent.role;

  /// Sends a prompt to this tool's agent.
  late final _sendMessageSpec = Tool(
    name: buildToolName('send_message'),
    description:
        'Send a message (prompt) to AI Agent ${_agent.displayName} (role: ${_agent.role}); '
        'returns the response from the Agent.',
    inputSchema: z.object(
      {'prompt': z.string('Instructions for the Agent.')},
      required: ['prompt'],
    ),
    onCall: _sendMessage,
  );

  Future<ToolSuccess<String>> _sendMessage(Json args) async {
    final prompt = args['prompt'] as String;
    modelInput.add(prompt);
    final fullResponse = StringBuffer();
    await for (var output in _agent.invoke(prompt)) {
      _agent.modelOutput.add(output);
      fullResponse.write(output);
    }
    // final response = await _agent.invoke(prompt);
    // _agent.modelOutput.add(response);
    return ToolSuccess(fullResponse.toString());
  }

  /// Clears the conversation history of this tool's agent (starts a new conversation).
  late final Tool _clearHistorySpec = Tool(
    name: buildToolName('clear_history'),
    description:
        'Clear the context window (conversation history) of AI Agent ${_agent.displayName} (role: ${_agent.role}); '
        'has same effect as starting a new conversation.',
    onCall: _clearHistory,
  );

  Future<ToolSuccess<String>> _clearHistory(Json args) async {
    modelInput.add('`${buildToolName('clear_history')}`');
    await _agent.startNewConversation(systemPrompt: _systemPrompt);
    return ToolSuccess.ok;
  }
}
