import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../conversations/check_point.dart';
import '../conversations/conversation_manager.dart';
import '../output_sinks/output_sink.dart';
import '../output_sinks/streaming_output_sink.dart';
import '../toolsets/toolset.dart';
import '../toolsets/toolset_combined.dart';
import '../utils/types.dart';
import 'agent_logger.dart';

class Agent {
  Agent(
    this.model, {
    this.modelOptions,
    String? displayName,
    this.role = '',
    String? systemInstructions,
    this.modelOutput = const NullOutputSink(),
    StreamingOutputSink? streamingOutput,
    StreamingOutputSink? streamingThinking,
    required this.conversationManager,
    this.onNewConversation,
    this.onError,
    ToolSet toolSet = ToolSet.empty,
  }) : _streamingOutput = streamingOutput,
       _streamingThinking = streamingThinking,
       _displayName = displayName,
       _systemPrompt = systemInstructions?.toSystemPrompt(),
       _toolSet = toolSet.isEmpty ? ToolSet.empty : CombinedToolSet({toolSet});

  final ConversationManager conversationManager;

  final String? _displayName;
  String get displayName => _displayName ?? _agent.displayName;

  final String role;

  dartantic.ChatMessage? _systemPrompt;
  set systemInstructions(String? instructions) {
    _systemPrompt = instructions?.toSystemPrompt();
  }

  final NewConversationCallback? onNewConversation;
  final ErrorCallback? onError;
  final OutputSink modelOutput;
  final StreamingOutputSink? _streamingOutput;
  final StreamingOutputSink? _streamingThinking;

  late final AgentLogger _agentLogger = AgentLogger(this);

  ToolSet _toolSet;
  Iterable<String> get toolNames => _toolSet.tools.map((t) => t.name);

  final String model;

  final dartantic.ChatModelOptions? modelOptions;

  late dartantic.Agent _agent = .new(
    model,
    chatModelOptions: modelOptions,
    displayName: _displayName,
    tools: _toolSet.tools,
  );

  dartantic.Provider get provider =>
      dartantic.Agent.getProvider(_agent.providerName);

  void registerToolSet(ToolSet additionalToolset) {
    _toolSet = CombinedToolSet({_toolSet, additionalToolset});
    _agent = .new(
      model,
      chatModelOptions: modelOptions,
      displayName: _displayName,
      tools: _toolSet.tools,
    );
  }

  String get chatModelName => _agent.chatModelName ?? model;

  Iterable<dartantic.ChatMessage> get history => conversationManager.history;

  Iterable<dartantic.ChatMessage> get messages =>
      conversationManager.history.where(
        (m) =>
            m.role != .system &&
            m.text.isNotEmpty &&
            !m.hasToolCalls &&
            !m.hasToolResults,
      );

  Iterable<dartantic.ChatMessage> get systemMessages =>
      conversationManager.systemMessages;

  Checkpoint getCheckPoint() => conversationManager.getCheckpoint();

  Future<bool> restoreCheckPoint(Checkpoint checkPoint) =>
      conversationManager.restoreCheckpoint(checkPoint);

  void compactHistory() => conversationManager.compact();

  Future<void> summarizeConversation() async {
    final response = await _agent.send(
      '**Summarize this conversation**\n'
      'Retain key information only, and any actions applied.\n'
      'Do not summarize questions asked.\n'
      'Do not summarize topics that were abandoned.\n'
      'Do not repeat yourself.\n'
      '\n'
      'Focus on:\n'
      '* **overall context**: what is the overall context of the conversation\n'
      '* **key information**: what has been discovered\n'
      '* **major outcomes**: what has been done\n'
      '* **impediments**: if any, what is blocking progress\n'
      '* **next steps**: if any, what needs to be done next\n',
      history: messages,
    );

    await conversationManager.setConversation([.model(response.output)]);
  }

  static final _wordBoundary = RegExp(r'\b');
  static final _digit = RegExp(r'[0-9]');
  static final _hexNumber = RegExp(r'^(0x)?[a-fA-F0-9_]+$');
  static final _word = RegExp(r'^[0-9\w]+$');

  static bool _shouldKeepLine(String line) {
    final parts = line.trim().split(_wordBoundary);
    for (var i = parts.length - 1; i >= 0; i--) {
      final p = parts[i].trim();
      if (p.isEmpty) {
        parts.removeAt(i);
      } else if (_digit.hasMatch(p) && _hexNumber.hasMatch(p)) {
        parts.removeAt(i);
      } else if (!_word.hasMatch(p)) {
        parts.removeAt(i);
      }
    }
    return parts.length > 2;
  }

  /// Returns the number of repeating messages (more than 20 repetitions).
  static int _checkRepetitions(String text, String mode) {
    final counts = <String, int>{};
    text.split('\n').map((l) => l.trim()).where(_shouldKeepLine).forEach((l) {
          counts.update(l, (n) => n + 1, ifAbsent: () => 1);
        });
    final entries = counts.entries.toList();
    entries.removeWhere((e) => e.value == 1);
    entries.sort((a, b) {
      final countDelta = b.value.compareTo(a.value);
      return (countDelta == 0)
          ? a.key.length.compareTo(b.key.length)
          : countDelta;
    });
    final mostRepeated = entries.where((e) => e.value > 20);
    if (mostRepeated.isNotEmpty) {
      print(
        'TOP 5 ${mode.toUpperCase()}:\n'
        '${mostRepeated.take(5).map((e) => ' - (${e.value}) ${e.key}').join('\n')}',
      );
    }
    return mostRepeated.length;
  }

  Stream<String> invoke(String prompt, {CancelationToken? token}) async* {
    late StreamSubscription<dartantic.ChatResult<String>> sub;
    final stream = StreamController<String>();

    await Future.wait([
      ?_streamingThinking?.start(),
      ?_streamingOutput?.start(),
    ]);

    var fullThoughts = '', fullOutput = '';

    Future<void> $register(dartantic.ChatResult<String> r) async {
      if (stream.isClosed) return;

      var isRepeating = false;

      final output = r.output;
      if (output.isNotEmpty) {
        _streamingOutput?.add(output);
        fullOutput += output;
        if (_checkRepetitions(fullOutput, 'output') > 2) {
          isRepeating = true;
        }
      }

      final thinking = r.thinking ?? '';
      if (thinking.isNotEmpty) {
        _streamingThinking?.add(thinking);
        fullThoughts += thinking;
        if (_checkRepetitions(fullThoughts, 'thinking') > 2) {
          isRepeating = true;
        }
      }

      if (isRepeating) {
        if (!stream.isClosed) {
          final msg =
              'It seems I am running in circles, and I am repeating myself. '
              'Please start over. '
              'If this happens again, try clearing my history before retrying.';
          final cancelled = dartantic.ChatMessage.model(msg);
          _agentLogger.log(cancelled);
          await conversationManager.register(
            dartantic.ChatResult(output: msg, messages: [cancelled]),
            toolSet: _toolSet,
          );
          stream.add(msg);
          stream.close();
        }
        sub.cancel();
        return;
      }

      if (r.messages
          .expand((m) => m.parts)
          .every((p) => p is dartantic.ThinkingPart)) {
        // thinking only
        return;
      }

      for (var m in r.messages) {
        _agentLogger.log(m);
      }
      _agentLogger.logUsage(r);

      await conversationManager.register(r, toolSet: _toolSet);

      for (var p
          in r.messages
              .where((m) => m.role == .model)
              .expand((m) => m.parts.whereType<dartantic.TextPart>())) {
        stream.add(p.text);
      }

      if (token != null && token.isCanceled) {
        if (!stream.isClosed) {
          final msg = token.exception?.message ?? '[Work interrupted by user]';
          final cancelled = dartantic.ChatMessage.user(msg);
          _agentLogger.log(cancelled);
          await conversationManager.register(
            dartantic.ChatResult(output: msg, messages: [cancelled]),
            toolSet: _toolSet,
          );
          stream.add(msg);
          stream.close();
        }
        sub.cancel();
      }
    }

    var pending = Future<void>.value();

    sub = _agent
        .sendStream(prompt, history: conversationManager.history)
        .listen(
          (r) => pending = pending.then((_) => $register(r)),
          onError: (ex, st) async {
            if (!stream.isClosed) {
              stream.addError(ex, st);
            }
            await pending;
            stream.close();
          },
          onDone: () {
            pending.then((_) async {
              stream.close();
              await Future.wait([
                ?_streamingThinking?.finish(),
                ?_streamingOutput?.finish(),
              ]);
            });
          },
          cancelOnError: true,
        );

    yield* stream.stream;
  }

  Future<int> startNewConversation() async {
    final systemPrompt = _systemPrompt;
    final chatId = await conversationManager.startConversation(systemPrompt);
    onNewConversation?.call();
    if (systemPrompt != null) _agentLogger.log(systemPrompt);
    return chatId;
  }

  Future<void> dispose() => Future.value();
}

extension on String {
  dartantic.ChatMessage? toSystemPrompt() {
    final prompt = trim();
    return prompt.isEmpty ? null : .system(prompt);
  }
}
