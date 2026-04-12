import 'dart:async';

import '../commands/command.dart';
import '../commands/command_registry.dart';
import '../commands/help_command.dart';
import '../commands/history_command.dart';
import '../commands/quit_command.dart';
import '../commands/summarize_command.dart';
import '../commands/system_prompt_command.dart';
import '../commands/tools_command.dart';
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
    super.streamingOutput,
    super.streamingThinkingOutput,
    super.toolSet,
    super.onError,
    required PromptCallback prompt,
    super.onNewConversation,
    CommandRegistry? commandRegistry,
  }) : _prompt = prompt,
       commandRegistry = commandRegistry ?? CommandRegistry() {
    // Register default commands if the registry is empty or new.
    if (this.commandRegistry.all.isEmpty) {
      this.commandRegistry.register(HelpCommand.to(modelOutput));
      this.commandRegistry.register(QuitCommand(callback: stopInteracting));
      this.commandRegistry.register(HistoryCommand.to(modelOutput));
      this.commandRegistry.register(SummarizeCommand.to(modelOutput));
      this.commandRegistry.register(SystemPromptCommand.to(modelOutput));
      this.commandRegistry.register(ToolsCommand.to(modelOutput));
    }
  }

  final PromptCallback _prompt;
  final CommandRegistry commandRegistry;

  Completer<void>? _completer;

  bool get isInteracting => _completer != null;

  Future<void> interactWithUser([UserCommandHandler? handleUserCommand]) {
    final completer = _completer ?? Completer<void>();
    if (_completer == completer) return completer.future;
    _completer = completer;

    (Command?, List<String>) $parseCommand(String input) {
      final parts = input.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty || !parts[0].startsWith('/')) return (null, []);

      final label = parts[0].substring(1);
      final args = parts.sublist(1);

      // Check external handler first
      var cmd = handleUserCommand?.call(label, args);
      // Then check internal registry
      cmd ??= commandRegistry.lookup(label);

      return (cmd, args);
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

          // invoke() will call onError and return a recovery string if available.
          // If it rethrows, it means the error was not "handled" (returned null).

          final response = await invokeStream(prompt);

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
