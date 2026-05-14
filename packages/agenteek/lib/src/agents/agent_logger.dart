import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../../agenteek_dbg.dart' as dbg;
import '../utils/log.dart';
import 'agent.dart';
import 'agent_interactive.dart';

class AgentLogger {
  AgentLogger(this.agent)
    : _logPrefix =
          '${(agent is InteractiveAgent) ? 'I' : 'A'}-${agent.displayName}';

  final Agent agent;
  final String _logPrefix;

  static final _loggers = <String, Log>{};

  Log? _currentLogger;
  Log? get currentLogger {
    final conversationId = agent.conversationManager.conversationId;
    if (conversationId < 0) return null;

    final ctxId = conversationId.getHexHashCode(8);
    final loggerName = '$_logPrefix-$ctxId';

    var logger = _currentLogger;
    if (logger == null || logger.name != loggerName) {
      logger?.forceDisable();
      logger = _loggers[loggerName];
      if (logger == null) {
        logger = Log(loggerName);
        logger.forceEnable();
        logger.append(
          '${agent.runtimeType} - ${agent.displayName} - ${agent.model}\n'
          'Context ID `$ctxId` - Tools: ${agent.toolNames.join(', ')}',
        );
        _loggers[loggerName] = logger;
      }
      logger.forceEnable();
    }

    return logger;
  }

  void log(dartantic.ChatMessage message) {
    final logger = currentLogger;
    if (logger == null) return;
    for (var p in [
      ...message.thinkingParts,
      ...message.toolParts,
      ...message.otherParts,
      ...message.textParts,
    ]) {
      logger.append(p.trace(message.role));
    }
  }

  static final _collapseWs = RegExp(r'\s+');

  void logUsage(dartantic.ChatResult result) {
    final usage = result.usage;
    if (usage == null) return;
    currentLogger?.append(
      'FINISH REASON: ${result.finishReason}\n'
      'USAGE: ${usage.toString().trim().replaceAll(_collapseWs, ' ')}',
    );
  }

  void trace(Object data) {
    final logger = currentLogger;
    if (logger == null) return;
    logger.append(data.toString());
  }
}

extension on dartantic.Part {
  String trace(dartantic.ChatMessageRole role) => switch (this) {
    dartantic.TextPart t =>
      '**${t._roleLabel(role)}**\n'
          '${t.text}',
    dartantic.ThinkingPart t =>
      '**${_roleLabel(role)} (thinking...)**\n'
          '${t.text}',
    dartantic.ToolPart t => switch (t.kind) {
      .call =>
        '=== CALLING ${t.toolCallId} ==>\n'
            '${t.arguments}\n'
            '=== CALLING ${t.toolCallId} ==>',
      .result =>
        '<== CALLED  ${t.toolCallId} ===\n'
            '${t.result}\n'
            '<== CALLED  ${t.toolCallId} ===',
    },
    _ =>
      '**${_roleLabel(role)} $runtimeType**\n'
          '${toString()}',
  };

  static String _roleLabel(dartantic.ChatMessageRole role) => switch (role) {
    .user => 'USER',
    .model => 'MODEL',
    .system => 'SYSTEM',
  };
}

extension on dartantic.TextPart {
  String _roleLabel(dartantic.ChatMessageRole role) => switch (role) {
    .user => 'USER PROMPT',
    .model => 'MODEL OUTPUT',
    .system => 'SYSTEM PROMPT',
  };
}

extension on dartantic.ToolPart {
  String get toolCallId => '"$toolName" ($callId)';
}

extension on dartantic.ChatMessage {
  Iterable<dartantic.ThinkingPart> get thinkingParts =>
      parts.whereType<dartantic.ThinkingPart>();

  Iterable<dartantic.ToolPart> get toolParts =>
      parts.whereType<dartantic.ToolPart>();

  Iterable<dartantic.TextPart> get textParts =>
      parts.whereType<dartantic.TextPart>();

  Iterable<dartantic.Part> get otherParts => parts.where(
    (p) =>
        p is! dartantic.TextPart &&
        p is! dartantic.ThinkingPart &&
        p is! dartantic.ToolPart,
  );
}
