import 'dart:async';

import 'package:agenteek/agenteek.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../utils/null_sink.dart';

class Agent {
  Agent(
    this.model, {
    this.modelOptions,
    String? displayName,
    String? systemPrompt,
    this.modelOutput = const NullSink(),
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

  Future<void> summarizeConversation() async {
    final response = await agent.send(
      'Summarize this conversation: '
      'retain key information only and any actions applied; '
      'do not summarize questions asked, focus on results.',
      history: messages,
    );

    await _conversationManager.setConversation([
      dartantic.ChatMessage.model(response.output),
    ]);
  }

  Future<String> invoke(String prompt) async {
    chatLogger.append(() => '[$name] RECEIVED PROMPT: $prompt');
    modelLogger.append(() => '[$name] PROCESSING PROMPT $prompt');

    try {
      final response = await agent.send(
        prompt,
        history: _conversationManager.history,
      );
      await _conversationManager.addAll(response.messages);
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
