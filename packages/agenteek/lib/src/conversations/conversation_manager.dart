import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../toolsets/toolset.dart';
import 'check_point.dart';

abstract class ConversationManager {
  Iterable<dartantic.ChatMessage> get systemMessages =>
      history.where((m) => m.role == .system && m.text.isNotEmpty);

  Iterable<dartantic.ChatMessage> get history;

  int get conversationId;

  Checkpoint getCheckpoint();

  Future<bool> restoreCheckpoint(Checkpoint checkPoint);

  void reset();

  Future<List<String>> listConversations();

  Future<int> startConversation([dartantic.ChatMessage? systemPrompt]);

  Future<bool> switchToConversation(int conversationId);

  Future<void> setConversation(Iterable<dartantic.ChatMessage> messages);

  Future<void> register(dartantic.ChatResult result, {ToolSet? toolSet});

  Future<bool> deleteConversation(int conversationId);

  void compact();
}

extension ChatResultExt on dartantic.ChatResult {
  dartantic.ChatResult? copyAndPrepare({
    bool keepThoughts = false,
    ToolSet? toolSet,
  }) {
    final keepMessages = messages
        .map(
          (m) => m.copyAndPrepare(keepThoughts: keepThoughts, toolSet: toolSet),
        )
        .nonNulls
        .toList();
    return keepMessages.isEmpty
        ? null
        : dartantic.ChatResult(
            output: output,
            finishReason: finishReason,
            metadata: {...metadata},
            usage: usage,
            messages: keepMessages,
            thinking: thinking,
            id: id,
          );
  }
}

extension ChatMessageExt on dartantic.ChatMessage {
  dartantic.ChatMessage? copyAndPrepare({
    bool keepThoughts = false,
    ToolSet? toolSet,
  }) {
    final keepParts = keepThoughts
        ? parts
        : parts.where((p) => p is! dartantic.ThinkingPart);
    return keepParts.isEmpty
        ? null
        : dartantic.ChatMessage(
            role: role,
            parts: keepParts
                .map((p) => dartantic.StandardPart.fromJson(p.toJson()))
                .toList(),
            metadata: {...metadata},
            finishStatus: finishStatus,
          );
  }
}

extension HistoryExt on List<dartantic.ChatMessage> {
  Future<void> redactObsoleteToolResults(ToolSet? toolSet) async {
    if (toolSet == null) return;
    final redacted = (await toolSet.redactObsoleteToolResults(
      this,
    )).entries.toList();
    for (var i = length - 1; i >= 0; i--) {
      if (redacted.isEmpty) break;
      final message = this[i];
      for (var j = redacted.length - 1; j >= 0; j--) {
        final entry = redacted[j];
        final idx = message.parts.indexOf(entry.key);
        if (idx >= 0) {
          final parts = [...message.parts];
          parts[idx] = entry.value;
          this[i] = message.copyWith(parts: parts);
          redacted.removeAt(j);
        }
      }
    }
  }
}
