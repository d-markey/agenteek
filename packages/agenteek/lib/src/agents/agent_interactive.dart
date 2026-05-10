import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';

import '../commands/built_in/clear_command.dart';
import '../commands/built_in/list_models_command.dart';
import '../commands/command.dart';
import '../commands/command_registry.dart';
import '../commands/built_in/compact_command.dart';
import '../commands/built_in/help_command.dart';
import '../commands/built_in/history_command.dart';
import '../commands/built_in/quit_command.dart';
import '../commands/built_in/summarize_command.dart';
import '../commands/built_in/system_messages_command.dart';
import '../commands/built_in/tools_command.dart';
import '../utils/debug.dart' as dbg;
import '../utils/types.dart';
import 'agent.dart';

class InteractiveAgent extends Agent {
  InteractiveAgent(
    super.model, {
    super.modelOptions,
    required super.conversationManager,
    super.displayName,
    super.role = '',
    super.systemInstructions = '',
    super.modelOutput,
    super.streamingOutput,
    super.streamingThinking,
    super.toolSet,
    super.onError,
    required PromptCallback prompt,
    super.onNewConversation,
    CommandRegistry? commandRegistry,
  }) : _prompt = prompt,
       commandRegistry = commandRegistry ?? CommandRegistry() {
    // Register default commands if the registry is empty or new.
    if (this.commandRegistry.all.isEmpty) {
      this.commandRegistry.register(QuitCommand(callback: stopInteracting));
      this.commandRegistry.register(ClearCommand.to(modelOutput));
      this.commandRegistry.register(HelpCommand.to(modelOutput));
      this.commandRegistry.register(HistoryCommand.to(modelOutput));
      this.commandRegistry.register(SummarizeCommand.to(modelOutput));
      this.commandRegistry.register(CompactCommand.to(modelOutput));
      this.commandRegistry.register(SystemMessagesCommand.to(modelOutput));
      this.commandRegistry.register(ToolsCommand.to(modelOutput));
      this.commandRegistry.register(ListModelsCommand.to(modelOutput));
    }
  }

  final PromptCallback _prompt;
  final CommandRegistry commandRegistry;

  Completer<void>? _completer;

  bool get isInteracting => _completer != null;

  Future<void> interactWithUser({
    UserCommandHandler? handleUserCommand,
    CancelationToken Function()? tokenFactory,
  }) {
    final completer = _completer ?? Completer<void>();
    if (_completer == completer) return completer.future;
    _completer = completer;

    (Command?, List<String>) $parseCommand(String input) {
      final parts = input.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty || !parts[0].startsWith('/')) return (null, []);
      final label = parts[0].substring(1), args = parts.sublist(1);
      return (
        // Check external handler first, then internal registry
        handleUserCommand?.call(label, args) ?? commandRegistry.lookup(label),
        args,
      );
    }

    var throttling = Future<void>.value();

    Future<void> $handleUserInput() async {
      while (!completer.isCompleted) {
        try {
          dbg.trace('Waiting for user input...');

          // handle prompt & commands
          String prompt;
          try {
            prompt = await _prompt();

            // handle command
            final (command, args) = $parseCommand(prompt);
            if (command != null) {
              prompt = await command.handle(this, args) ?? '';
            }
          } catch (ex, st) {
            await onError?.call(ex, st);
            continue;
          }

          // handle prompt
          if (prompt.isEmpty) continue;

          // In case of problem, invokeStream() will call onError() and return a recovery string if available.
          // If it rethrows, it means the error was not "handled" (returned null).

          await throttling;

          await for (var response in invoke(
            prompt,
            token: tokenFactory?.call(),
          )) {
            if (response.trim().isNotEmpty) {
              modelOutput.add(response);
            }
          }
        } catch (ex, st) {
          // This should be an unexpected error that escaped the inner blocks.
          // If invokeStream() threw, onError was already called once.
          dbg.error('!!! UNHANDLED ERROR: $ex\n$st');
        } finally {
          throttling = Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    unawaited($handleUserInput());
    return completer.future;
  }

  void stopInteracting() {
    final completer = _completer;
    if (completer == null) return;
    if (!completer.isCompleted) completer.complete();
    // reset completer and chat history
    _completer = null;
  }
}
