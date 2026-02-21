import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../utils/unique_id.dart';
import 'check_point.dart';
import 'conversation_manager.dart';

class InMemoryConversationManager extends ConversationManager {
  final _conversations = <int, List<dartantic.ChatMessage>>{};

  int _conversationId = -1;
  List<dartantic.ChatMessage> _history = <dartantic.ChatMessage>[];
  final _checkpoints = <String>[];
  final _uniqueId = UniqueIdGenerator();

  void _register(dartantic.ChatMessage? message) {
    if (message != null) {
      _history.add(message);
      _checkpoints.add(_uniqueId.string());
    }
  }

  @override
  Iterable<dartantic.ChatMessage> get systemInstructions =>
      _history.where((m) => m.role == dartantic.ChatMessageRole.system);

  @override
  Iterable<dartantic.ChatMessage> get history => _history;

  Future<List<dartantic.ChatMessage>> _load(int conversationId) async {
    final history = _conversations[conversationId];
    if (history == null) {
      throw Exception('Conversation $conversationId not found.');
    }
    return history;
  }

  @override
  Future<int> startConversation([
    dartantic.ChatMessage? systemInstructions,
  ]) async {
    _conversationId = _uniqueId.next();
    _history = [];
    _conversations[_conversationId] = _history;
    _checkpoints.clear();
    _register(systemInstructions);
    return _conversationId;
  }

  @override
  Future<bool> switchToConversation(int conversationId) async {
    final history = await _load(conversationId);
    _conversationId = conversationId;
    _history = history;
    _checkpoints.clear();
    _checkpoints.addAll(
      Iterable.generate(history.length, (_) => _uniqueId.string()),
    );
    return true;
  }

  @override
  Future<void> setConversation(Iterable<dartantic.ChatMessage> messages) async {
    if (_conversationId < 0) await startConversation();
    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].role != dartantic.ChatMessageRole.system) {
        _history.removeAt(i);
        _checkpoints.removeAt(i);
      }
    }
    messages.forEach(_register);
  }

  @override
  Future<void> add(dartantic.ChatMessage message) async {
    if (_conversationId < 0) await startConversation();
    _register(message);
  }

  @override
  Future<void> addAll(Iterable<dartantic.ChatMessage> messages) async {
    if (_conversationId < 0) await startConversation();
    messages.forEach(_register);
  }

  @override
  Future<bool> deleteConversation(int conversationId) async {
    if (conversationId == _conversationId) return false;
    _conversations.remove(conversationId);
    return true;
  }

  @override
  CheckPoint getCheckPoint() => CheckPoint(_checkpoints.last);

  @override
  Future<bool> restoreCheckPoint(CheckPoint checkPoint) {
    for (var i = _checkpoints.length - 1; i >= 0; i--) {
      if (checkPoint.id == _checkpoints[i]) {
        _checkpoints.length = i + 1;
        _history.length = i + 1;
        return Future.value(true);
      }
    }
    return Future.value(false);
  }

  @override
  void reset() {
    _conversationId = -1;
    _history = [];
    _checkpoints.clear();
  }
}
