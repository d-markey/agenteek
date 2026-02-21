// user command handler
import 'dart:io';

import 'package:agenteek/agenteek.dart';

Command? userCommandHandler(String input) {
  var command = input.toLowerCase();
  switch (command) {
    case '':
      return ConfirmAndQuitCommand();

    case '/exit':
    case '/quit':
    case '/q':
    case '/x':
      return const QuitCommand();

    case '/help':
    case '/h':
    case '/?':
      return const HelpCommand();

    case '/tools':
      return const ToolsCommand();

    case '/history':
      return const HistoryCommand();

    // TODO
    // case '/summarize':
    //   return const SummarizeCommand();

    case '/systemprompt':
    case '/system-prompt':
      return const SystemPromptCommand();

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
      '   /new               start a new conversation\n'
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

// TODO
// class SummarizeCommand extends Command {
//   const SummarizeCommand();

//   @override
//   Future<Null> handle(Agent agent) async {
//     print('Summarize conversation:\n*****');
//     await agent.summarizeConversation();
//     print('Here\'s the summary:\n*****');
//     for (var message in agent.history) {
//       print(message);
//     }
//     print('*****');
//     return null;
//   }
// }

class ConfirmAndQuitCommand extends Command {
  const ConfirmAndQuitCommand();

  @override
  Future<String?> handle(Agent agent) async {
    stdout.writeln('Do you really want to quit (y/N)? ');
    final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    return (answer == 'y' || answer == 'yes')
        ? const QuitCommand().handle(agent)
        : null;
  }
}
