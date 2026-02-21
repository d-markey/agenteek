import 'dart:io';

import 'package:agenteek/agenteek.dart';

Command? commandHandler(String input) {
  var command = input.toLowerCase();
  switch (command) {
    case '/exit':
    case '/quit':
    case '/q':
    case '/x':
      return const QuitCommand();

    case '':
      stdout.writeln('Do you really want to quit (y/N)? ');
      command = stdin.readLineSync()?.trim().toLowerCase() ?? '';
      return (command == 'y' || command == 'yes') ? const QuitCommand() : null;

    case '/help':
    case '/h':
    case '/?':
      return const HelpCommand();

    case '/tools':
      return const ToolsCommand();

    case '/history':
      return const HistoryCommand();

    case '/new':
      return const NewConversationCommand();

    default:
      return null;
  }
}

class HelpCommand extends Command {
  const HelpCommand();

  @override
  Null handle(Agent _) {
    print(
      'USAGE:\n'
      '   /exit    /x, /q    quits\n'
      '   /help    /h, /?    displays help page\n'
      '   /history           dumps current chat history\n'
      '   /new               starts a new conversation\n'
      '   /tools             lists available tools\n',
    );
    return null;
  }
}

class NewConversationCommand extends Command {
  const NewConversationCommand();

  @override
  Null handle(Agent agent) {
    print('Start a new conversation');
    agent.startNewConversation();
    return null;
  }
}
