import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:logging/logging.dart';

import '../conversations/check_point.dart';
import '../conversations/conversation_manager.dart';
import '../output_sinks/output_sink.dart';
import '../output_sinks/streaming_output_sink.dart';
import '../toolsets/toolset.dart';
import '../toolsets/toolset_combined.dart';
import '../utils/types.dart';
import 'accumulator.dart';
import 'agent_logger.dart';
import 'agent_throttling_logger.dart';

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

  Logger get logger => Logger('agenteek.agent.${displayName.toLowerCase()}');

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

  late final AgentLogger _agentLogger = AgentThrottlingLogger(
    this,
    const Duration(milliseconds: 500),
  );

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

  Stream<String> invoke(String prompt, {CancelationToken? token}) async* {
    late StreamSubscription<dartantic.ChatResult<String>> sub;
    final streamController = StreamController<String>();

    await Future.wait([
      ?_streamingThinking?.start(),
      ?_streamingOutput?.start(),
    ]);

    Future<void> $bailOut(String message) async {
      if (!streamController.isClosed) {
        final msg = dartantic.ChatMessage.model(message);
        _agentLogger.log(msg);
        await conversationManager.register(
          dartantic.ChatResult(output: message, messages: [msg]),
          toolSet: _toolSet,
        );
        streamController.add(message);
        streamController.close();
      }
      sub.cancel();
    }

    final thinkingAccumulator = Accumulator('thinking');
    final outputAccumulator = Accumulator('output');

    Future<void> $register(dartantic.ChatResult<String> r) async {
      if (streamController.isClosed) {
        sub.cancel();
        return;
      }

      var isRepeating = false;

      final output = r.output;
      if (output.isNotEmpty) {
        _streamingOutput?.add(output);
        if (outputAccumulator.accumulate(output)) {
          final repetitions = outputAccumulator.checkRepetitions();
          isRepeating |= (repetitions.$1 > 2 || repetitions.$2 > 0);
        }
      }

      final thinking = r.thinking ?? '';
      if (thinking.isNotEmpty) {
        _streamingThinking?.add(thinking);
        if (thinkingAccumulator.accumulate(thinking)) {
          final repetitions = thinkingAccumulator.checkRepetitions();
          isRepeating |= (repetitions.$1 > 2 || repetitions.$2 > 0);
        }
      }

      if (isRepeating) {
        return $bailOut(
          'It seems I am running in circles, and I am repeating myself. '
          'Please start over. '
          'If this happens again, try clearing my history before retrying.',
        );
      }

      // stop here if only thinking
      if (r.messages.every(
        (m) => m.parts.every((p) => p is dartantic.ThinkingPart),
      )) {
        return;
      }

      r.messages.forEach(_agentLogger.log);
      _agentLogger.logUsage(r);

      await conversationManager.register(r, toolSet: _toolSet);

      if (streamController.isClosed) {
        sub.cancel();
        return;
      }

      for (final msg in r.messages.where((m) => m.role == .model)) {
        for (final part in msg.parts.whereType<dartantic.TextPart>()) {
          streamController.add(part.text);
        }
      }

      if (token != null && token.isCanceled) {
        return $bailOut(
          token.exception?.message ?? '[Work interrupted by user]',
        );
      }
    }

    var pending = Future<void>.value();
    int depth = 0, remaining = 0;

    sub = _agent
        .sendStream(prompt, history: conversationManager.history)
        .listen(
          (r) {
            pending = pending.then((_) {
              remaining--;
              return $register(r);
            });
            remaining++;
            depth++;
          },
          onError: (ex, st) async {
            logger.fine('[E] ($depth/$remaining) Error $ex\n$st');
            if (!streamController.isClosed) {
              streamController.addError(ex, st);
            }
            await pending;
            logger.fine('[E] ($depth/$remaining) closing now');
            streamController.close();
          },
          onDone: () {
            logger.fine('[D] ($depth/$remaining) Done');
            pending.then((_) async {
              logger.fine('[D] ($depth/$remaining) closing now');
              streamController.close();
              await Future.wait([
                ?_streamingThinking?.finish(),
                ?_streamingOutput?.finish(),
              ]);
            });
          },
          cancelOnError: true,
        );

    yield* streamController.stream;
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
