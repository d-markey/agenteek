import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import 'check_point.dart';

abstract class ConversationManager {
  Iterable<dartantic.ChatMessage> get systemInstructions;

  Iterable<dartantic.ChatMessage> get history;

  CheckPoint getCheckPoint();

  Future<bool> restoreCheckPoint(CheckPoint checkPoint);

  void reset();

  Future<int> startConversation([dartantic.ChatMessage? systemInstructions]);

  Future<bool> switchToConversation(int conversationId);

  Future<void> setConversation(Iterable<dartantic.ChatMessage> messages);

  Future<void> add(dartantic.ChatMessage message);

  Future<void> addAll(Iterable<dartantic.ChatMessage> messages);

  Future<bool> deleteConversation(int conversationId);
}
