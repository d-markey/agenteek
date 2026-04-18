import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../conversations/check_point.dart';
import '../conversations/conversation_manager.dart';
import '../toolsets/toolset.dart';
import '../toolsets/toolset_base.dart';
import '../utils/log.dart';
import '../utils/null_sink.dart';
import '../utils/types.dart';
import '_accumulator.dart';
import 'streaming_sink.dart';
import 'user_cancellation_exception.dart';

class Agent {
  Agent(
    this.model, {
    this.modelOptions,
    String? displayName,
    String? systemPrompt,
    this.modelOutput = const NullSink(),
    this.streamingOutput,
    this.streamingThinkingOutput,
    required ConversationManager conversationManager,
    this.onNewConversation,
    this.onError,
    this.toolSet = ToolSet.empty,
  }) : _conversationManager = conversationManager,
       _displayName = displayName,
       systemPrompt = (systemPrompt != null && systemPrompt.trim().isNotEmpty)
           ? dartantic.ChatMessage.system(systemPrompt)
           : null;

  final ConversationManager _conversationManager;

  final String? _displayName;
  String get name => _displayName ?? agent.displayName;

  final NewConversationCallback? onNewConversation;
  final ErrorCallback? onError;
  final Sink<String> modelOutput;
  final StreamingStringSink? streamingOutput;
  final StreamingStringSink? streamingThinkingOutput;

  final ToolSetBase toolSet;
  Iterable<String> get toolNames => toolSet.tools.map((t) => t.name);

  final String model;

  final dartantic.ChatModelOptions? modelOptions;
  final dartantic.ChatMessage? systemPrompt;

  late final dartantic.Agent agent = dartantic.Agent(
    model,
    chatModelOptions: modelOptions,
    displayName: _displayName,
    tools: toolSet.tools,
  );

  Iterable<dartantic.ChatMessage> get history => _conversationManager.history;

  Iterable<dartantic.ChatMessage> get messages =>
      _conversationManager.history.where(
        (m) =>
            m.role != dartantic.ChatMessageRole.system &&
            m.text.isNotEmpty &&
            !m.hasToolCalls &&
            !m.hasToolResults,
      );

  CheckPoint getCheckPoint() => _conversationManager.getCheckPoint();

  Future<bool> restoreCheckPoint(CheckPoint checkPoint) =>
      _conversationManager.restoreCheckPoint(checkPoint);

  void compactHistory() => _conversationManager.compact();

  Future<void> summarizeConversation() async {
    final response = await agent.send(
      '**Summarize this conversation**\n'
      'Retain key information only, and any actions applied. '
      'Do not summarize questions asked, but focus on:\n'
      '* **key information** discovered\n'
      '* **major outcomes** such as new features, modifications applied, etc.\n',
      history: messages,
    );

    await _conversationManager.setConversation([
      dartantic.ChatMessage.model(response.output),
    ]);
  }

  Future<String> invokeStream(String prompt, {CancelationToken? token}) async {
    chatLogger.append(() => '[$name] RECEIVED PROMPT: $prompt');
    modelLogger.append(() => '[$name] PROCESSING PROMPT $prompt');

    try {
      await streamingThinkingOutput?.start();
      await streamingOutput?.start();

      final accumulator = AgentResponseAccumulator(
        streamingOutput: streamingOutput,
        streamingThinkingOutput: streamingThinkingOutput,
      );

      late StreamSubscription<dartantic.ChatResult<String>> sub;
      sub = agent
          .sendStream(prompt, history: _conversationManager.history)
          .listen(
            accumulator.add,
            onError: (ex, st) {
              print('$ex @ $st');
            },
            onDone: () {
              print('Done.');
            },
          );

      await Future.any(
        [
          sub.asFuture(),
          token?.onCanceled.then((_) => sub.cancel()),
        ].whereType<Future>(),
      );

      final finalResult = accumulator.buildFinal();
      await _conversationManager.register(finalResult);
      modelLogger.append(finalResult.output);

      if (token != null && token.isCanceled) {
        throw UserCancellationException(
          message: token.exception?.message ?? 'Cancelled at your request.',
          pendingOutput: finalResult.output,
        );
      } else {
        return finalResult.output;
      }
    } catch (ex, st) {
      final recovery = await onError?.call(ex, st);
      if (recovery != null) return recovery;
      rethrow;
    } finally {
      await Future.wait([
        ?streamingThinkingOutput?.finish(),
        ?streamingOutput?.finish(),
      ]);
    }
  }

  Future<String> invoke(String prompt) async {
    chatLogger.append(() => '[$name] RECEIVED PROMPT: $prompt');
    modelLogger.append(() => '[$name] PROCESSING PROMPT $prompt');

    try {
      final response = await agent.send(
        prompt,
        history: _conversationManager.history,
      );
      await _conversationManager.register(response);
      modelLogger.append(response.output);
      return response.output;
    } catch (ex, st) {
      final recovery = await onError?.call(ex, st);
      if (recovery != null) return recovery;
      rethrow;
    }
  }

  Future<int> startNewConversation() async {
    final chatId = await _conversationManager.startConversation(systemPrompt);
    onNewConversation?.call();
    return chatId;
  }

  Future<void> dispose() => Future.value();
}
