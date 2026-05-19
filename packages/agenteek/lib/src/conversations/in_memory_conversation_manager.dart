import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../toolsets/toolset.dart';
import '../utils/unique_id.dart';
import 'chat_message_ext.dart';
import 'check_point.dart';
import 'conversation_manager.dart';

class InMemoryConversationManager extends ConversationManager {
  InMemoryConversationManager();

  var _history = <dartantic.ChatMessage>[];
  final _checkpoints = <String>[];
  final _uniqueId = UniqueIdGenerator();

  int _conversationId = -1;

  final _historyMap = <int, List<dartantic.ChatMessage>>{};

  @override
  int get conversationId => _conversationId;

  void _register(dartantic.ChatMessage? message) {
    if (message != null) {
      _history.add(message);
      _checkpoints.add(_uniqueId.string());
    }
  }

  void _resetCheckpoints() {
    _checkpoints.clear();
    for (var i = 0; i < _history.length; i++) {
      _checkpoints.add(_uniqueId.string());
    }
  }

  @override
  Iterable<dartantic.ChatMessage> get history => _history;

  @override
  Future<List<String>> listConversations() => Future.value(
    _historyMap.keys.map((c) => c.toRadixString(16).padLeft(8, '0')).toList(),
  );

  @override
  Future<int> startConversation([dartantic.ChatMessage? systemPrompt]) async {
    final conversationId = _uniqueId.next();
    _history = [];
    _historyMap[conversationId] = _history;
    _checkpoints.clear();
    _register(systemPrompt);
    _conversationId = conversationId;
    return conversationId;
  }

  @override
  Future<bool> switchToConversation(int conversationId) {
    _history = _historyMap[conversationId]!;
    _resetCheckpoints();
    _conversationId = conversationId;
    return Future.value(true);
  }

  @override
  Future<void> setConversation(Iterable<dartantic.ChatMessage> messages) async {
    if (_conversationId < 0) await startConversation();
    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].role != .system) {
        _history.removeAt(i);
        _checkpoints.removeAt(i);
      }
    }
    messages.forEach(_register);
  }

  @override
  Future<void> register(dartantic.ChatResult result, {ToolSet? toolSet}) async {
    final copy = result.copyAndPrepare(keepThoughts: false);
    if (copy == null) return;

    if (_conversationId < 0) await startConversation();

    copy.messages.forEach(_register);

    await _history.redactObsoleteToolResults(toolSet);
  }

  @override
  Future<bool> deleteConversation(int conversationId) {
    if (conversationId == _conversationId) return Future.value(false);
    _historyMap.remove(conversationId);
    return Future.value(true);
  }

  @override
  Checkpoint getCheckpoint() => Checkpoint(_checkpoints.last);

  @override
  Future<bool> restoreCheckpoint(Checkpoint checkpoint) {
    for (var i = _checkpoints.length - 1; i >= 0; i--) {
      if (checkpoint.id == _checkpoints[i]) {
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

  @override
  void compact() {
    for (var i = _history.length - 1; i >= 0; i--) {
      _history[i] = _history[i].compact();
      if (_history[i].isEmpty) {
        _history.removeAt(i);
        _checkpoints.removeAt(i);
      }
    }
  }
}
