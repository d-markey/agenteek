import 'dart:async';
import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../file_system/file_system.dart';
import '../utils/types.dart';
import '../utils/unique_id.dart';
import 'check_point.dart';
import 'conversation_manager.dart';

class FileSystemConversationManager extends ConversationManager {
  FileSystemConversationManager(this._fileSystem);

  final FileSystem _fileSystem;

  int _conversationId = -1;
  final _history = <dartantic.ChatMessage>[];
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
  Iterable<dartantic.ChatMessage> get history =>
      _history.where((m) => m.role != dartantic.ChatMessageRole.system);

  String get _fileName =>
      'chat_${_conversationId.toRadixString(16).padLeft(8, '0')}.ai.chat';

  Future<List<dartantic.ChatMessage>> _load(int conversationId) async {
    final json = await _fileSystem.read(_fileName);
    return (jsonDecode(json) as List)
        .cast<Json>()
        .map(dartantic.ChatMessage.fromJson)
        .toList();
  }

  Future<void> _save() async {
    if (_conversationId < 0) return;
    final json = jsonEncode(_history.map((m) => m.toJson()).toList());
    await _fileSystem.write(_fileName, json);
  }

  @override
  Future<int> startConversation([
    dartantic.ChatMessage? systemInstructions,
  ]) async {
    final conversationId = _uniqueId.next();
    _history.clear();
    _checkpoints.clear();
    _register(systemInstructions);
    _conversationId = conversationId;
    await _save();
    return conversationId;
  }

  @override
  Future<bool> switchToConversation(int conversationId) async {
    final history = await _load(conversationId);
    _conversationId = conversationId;
    _history.clear();
    _checkpoints.clear();
    history.forEach(_register);
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
    await _save();
  }

  @override
  Future<void> add(dartantic.ChatMessage message) async {
    if (_conversationId < 0) await startConversation();
    _register(message);
    await _save();
  }

  @override
  Future<void> addAll(Iterable<dartantic.ChatMessage> messages) async {
    if (_conversationId < 0) await startConversation();
    messages.forEach(_register);
    await _save();
  }

  @override
  Future<bool> deleteConversation(int conversationId) async {
    if (conversationId == _conversationId) return false;
    await _fileSystem.delete(_fileName);
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
        return _save().then((_) => true);
      }
    }
    return Future.value(false);
  }

  @override
  void reset() {
    _conversationId = -1;
    _history.clear();
    _checkpoints.clear();
  }
}
