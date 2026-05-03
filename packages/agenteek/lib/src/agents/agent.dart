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
       _toolSet = toolSet.isEmpty ? ToolSet.empty : CombinedToolSet({toolSet});

  final ConversationManager conversationManager;

  final String? _displayName;
  String get displayName => _displayName ?? _agent.displayName;

  final String role;

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

  Iterable<dartantic.ChatMessage> get systemPrompts => conversationManager
      .history
      .where((m) => m.role == .system && m.text.isNotEmpty);

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

  int _checkRepetitions(String text) {
    final counts = <String, int>{};
    text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('```') && l != '}')
        .forEach((l) {
          counts.update(l, (n) => n + 1, ifAbsent: () => 1);
        });
    final entries = counts.entries.toList();
    entries.removeWhere((e) => e.value == 1);
    entries.sort((a, b) => b.value.compareTo(a.value));
    if (entries.where((e) => e.value > 20).isNotEmpty) {
      print(
        'TOP 3 THOUGHTS:\n${entries.take(3).map((e) => '  (${e.value}) ${e.key}').join('\n')}',
      );
    }
    return entries.where((e) => e.value > 20).length;
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
        if (_checkRepetitions(fullOutput) > 2) {
          isRepeating = true;
        }
      }

      final thinking = r.thinking ?? '';
      if (thinking.isNotEmpty) {
        _streamingThinking?.add(thinking);
        fullThoughts += thinking;
        if (_checkRepetitions(fullThoughts) > 2) {
          isRepeating = true;
        }
      }

      if (isRepeating) {
        if (!stream.isClosed) {
          final msg =
              'I seem to be lost in circles, and I am repeating myself. Please start over.';
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
        fullOutput = '';
        fullThoughts = '';
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

  Future<int> startNewConversation({String? systemPrompt}) async {
    systemPrompt = systemPrompt?.trim() ?? '';
    final systemMessage = systemPrompt.isEmpty
        ? null
        : dartantic.ChatMessage.system(systemPrompt);
    final chatId = await conversationManager.startConversation(systemMessage);
    onNewConversation?.call();
    if (systemMessage != null) {
      _agentLogger.log(systemMessage);
    }
    return chatId;
  }

  Future<void> dispose() => Future.value();
}
