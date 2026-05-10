// user command handler
import 'dart:io';

import 'package:agenteek/agenteek.dart';

Command? userCommandHandler(String label, List<String> args) {
  switch (label.toLowerCase()) {
    case '':
      return const ConfirmAndQuitCommand();

    case 'exit':
    case 'quit':
    case 'q':
    case 'x':
      return const QuitCommand();

    case 'help':
    case 'h':
    case '?':
      return const HelpCommand();

    case 'tools':
      return const ToolsCommand();

    case 'history':
      return const HistoryCommand();

    case 'summarize':
    case 'sum':
      return const SummarizeCommand();

    case 'systemprompt':
    case 'system-prompt':
    case 'system':
      return const SystemPromptCommand();

    case 'new':
      return const NewConversationCommand();

    default:
      return null;
  }
}

class HelpCommand extends Command {
  const HelpCommand();

  @override
  String get name => 'help';

  @override
  String get description => 'Show this help page.';

  @override
  Null handle(Agent _, List<String> args) {
    print(
      'USAGE:\n'
      '   /exit    /x, /q    quits\n'
      '   /help    /h, /?    displays help page\n'
      '   /history           dumps current chat history\n'
      '   /new               start a new conversation\n'
      '   /tools             lists available tools\n',
    );
    return null;
  }
}

class NewConversationCommand extends Command {
  const NewConversationCommand();

  @override
  String get name => 'new';

  @override
  String get description => 'Start a new conversation.';

  @override
  Null handle(Agent agent, List<String> args) {
    print('Start a new conversation');
    agent.startNewConversation();
    return null;
  }
}

class ConfirmAndQuitCommand extends Command {
  const ConfirmAndQuitCommand();

  @override
  String get name => 'confirm-quit';

  @override
  String get description => 'Confirm before quitting (internal).';

  @override
  Future<String?> handle(Agent agent, List<String> args) async {
    stdout.writeln('Do you really want to quit (y/N)? ');
    final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    return (answer == 'y' || answer == 'yes')
        ? const QuitCommand().handle(agent, args)
        : null;
  }
}
