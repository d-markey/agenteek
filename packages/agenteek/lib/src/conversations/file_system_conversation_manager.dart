import 'dart:async';
import 'dart:convert';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:path/path.dart' as p;

import '../../agenteek_dbg.dart' as dbg;
import '../file_system/file_system.dart';
import '../toolsets/toolset.dart';
import '../utils/types.dart';
import '../utils/unique_id.dart';
import 'chat_message_ext.dart';
import 'check_point.dart';
import 'conversation_manager.dart';

class FileSystemConversationManager extends ConversationManager {
  FileSystemConversationManager(FileSystem fileSystem)
    : _fileSystem = fileSystem;

  final FileSystem _fileSystem;

  final _history = <dartantic.ChatMessage>[];
  final _checkpoints = <String>[];
  final _uniqueId = UniqueIdGenerator();

  int _conversationId = -1;

  @override
  int get conversationId => _conversationId;

  void _register(dartantic.ChatMessage? message) {
    if (message != null) {
      _history.add(message);
      _checkpoints.add(_uniqueId.string());
    }
  }

  @override
  Iterable<dartantic.ChatMessage> get history => _history;

  String _getFileName({int? conversationId}) =>
      'chat_${(conversationId ?? _conversationId).toRadixString(16).padLeft(8, '0')}.ai.chat';

  static final _chatFileNamePattern = RegExp('chat_[0-9a-fA-F]{8}\\.ai\\.chat');

  Future<List<dartantic.ChatMessage>> _load(int conversationId) async {
    final fileName = _getFileName(conversationId: conversationId);
    final json = await _fileSystem.read(fileName);
    return (jsonDecode(json) as List)
        .cast<Json>()
        .map(dartantic.ChatMessage.fromJson)
        .toList();
  }

  static final _jsonEncoder = JsonEncoder.withIndent('  ');

  Future<void> _save() async {
    if (_conversationId < 0) return;
    final json = _jsonEncoder.convert(
      _history
          .map((m) => m.toJson().without('_google_thought_signatures'))
          .toList(),
    );
    await _fileSystem.write(_getFileName(), json);
  }

  @override
  Future<List<String>> listConversations() => _fileSystem.list().where((f) {
    final fn = p.basename(f);
    return _chatFileNamePattern.hasMatch(fn);
  }).toList();

  @override
  Future<int> startConversation([dartantic.ChatMessage? systemPrompt]) async {
    final conversationId = _uniqueId.next();
    _history.clear();
    _checkpoints.clear();
    _register(systemPrompt);
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
      if (_history[i].role != .system) {
        _history.removeAt(i);
        _checkpoints.removeAt(i);
      }
    }
    messages.forEach(_register);
    await _save();
  }

  @override
  Future<void> register(dartantic.ChatResult result, {ToolSet? toolSet}) async {
    final copy = result.copyAndPrepare(keepThoughts: false, toolSet: toolSet);
    if (copy == null) return;

    if (_conversationId < 0) await startConversation();

    copy.messages.forEach(_register);

    final sideEffects = (await toolSet?.checkSideEffects(copy)) ?? '';
    if (sideEffects.isNotEmpty) {
      _register(.system('**Side Effects**:\n$sideEffects'));
      print('Side Effects:\n$sideEffects');
    }

    await _history.redactObsoleteToolResults(toolSet);

    await _save();
  }

  @override
  Future<bool> deleteConversation(int conversationId) async {
    if (conversationId == _conversationId) return false;
    final fileName = _getFileName(conversationId: conversationId);
    await _fileSystem.delete(fileName);
    return true;
  }

  @override
  Checkpoint getCheckpoint() => Checkpoint(_checkpoints.last);

  @override
  Future<bool> restoreCheckpoint(Checkpoint checkPoint) {
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
