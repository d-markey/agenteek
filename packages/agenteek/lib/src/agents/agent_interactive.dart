import 'dart:async';

import '../commands/command.dart';
import '../commands/quit_command.dart';
import '../utils/debug.dart' as dbg;
import '../utils/types.dart';
import 'agent.dart';

class InteractiveAgent extends Agent {
  InteractiveAgent(
    super.model, {
    super.modelOptions,
    required super.conversationManager,
    super.displayName,
    super.systemPrompt,
    super.modelOutput,
    super.toolSet,
    super.onError,
    required PromptCallback prompt,
    super.onNewConversation,
  }) : _prompt = prompt;

  final PromptCallback _prompt;

  Completer<void>? _completer;

  bool get isInteracting => _completer != null;

  Future<void> interactWithUser([UserCommandHandler? handleUserCommand]) {
    final completer = _completer ?? Completer<void>();
    if (_completer == completer) return completer.future;
    _completer = completer;

    Command? $getCommand(String prompt) {
      final cmd = handleUserCommand?.call(prompt);
      return (cmd == null && prompt.toLowerCase().trim() == '/quit')
          ? QuitCommand()
          : cmd;
    }

    Future<void> $handleUserInput() async {
      while (!completer.isCompleted) {
        try {
          dbg.trace('Waiting for user input...');

          // handle prompt & commands
          String prompt;
          try {
            prompt = await _prompt();

            // handle command
            final command = $getCommand(prompt);
            if (command != null) {
              prompt = await command.handle(this) ?? '';
            }
          } catch (ex, st) {
            await onError?.call(ex, st);
            continue;
          }

          // handle prompt
          if (prompt.isEmpty) continue;

          // invoke() will call onError and return a recovery string if available.
          // If it rethrows, it means the error was not "handled" (returned null).
          final response = await invoke(prompt);

          if (response.trim().isNotEmpty) {
            modelOutput.add(response);
          }
        } catch (ex) {
          dbg.trace('!!! UNHANDLED ERROR: $ex');
          // If invoke() threw, onError was already called once.
          // We call it again here only if it's an unexpected error
          // that escaped the inner blocks.
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
