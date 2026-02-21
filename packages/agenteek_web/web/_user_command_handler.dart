import 'dart:async';

import 'package:agenteek/agenteek.dart';

import '_html_sink.dart';

class HelpCommand extends Command {
  const HelpCommand.to(this.output);

  final Sink<String> output;

  @override
  Null handle(Agent _) {
    output.add(
      '```\n'
      'USAGE:\n'
      '   /help    /h, /?    displays help page\n'
      '   /history           dumps current chat history\n'
      '   /new               start a new conversation\n'
      '   /tools             lists available tools\n'
      '```',
    );
    if (output case HtmlNestedSink nested) nested.close();
    return null;
  }
}

class NewConversationCommand extends Command {
  const NewConversationCommand(this.output);

  final Sink<String> output;

  @override
  Null handle(Agent agent) {
    output.add('Start a new conversation');
    if (output case HtmlNestedSink nested) nested.close();
    agent.startNewConversation();
    return null;
  }
}

class HtmlHistoryCommand extends HistoryCommand {
  const HtmlHistoryCommand();

  HtmlHistoryCommand.to(super.output) : super.to();

  @override
  Null handle(Agent agent) {
    super.handle(agent);
    if (output case HtmlNestedSink nested) nested.close();
    return null;
  }
}

class HtmlSummarizeCommand extends SummarizeCommand {
  const HtmlSummarizeCommand();

  HtmlSummarizeCommand.to(super.output) : super.to();

  @override
  FutureOr<Null> handle(Agent agent) async {
    await super.handle(agent);
    if (output case HtmlNestedSink nested) nested.close();
    return null;
  }
}
