import 'dart:async';

import 'package:agenteek/agenteek.dart';

import '_html_sink.dart';

class HelpCommand extends Command {
  const HelpCommand.to(this.output);

  final Sink<String> output;

  @override
  String get name => 'help';

  @override
  String get description => 'Show this help page.';

  @override
  Null handle(Agent _, List<String> args) {
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
  String get name => 'new';

  @override
  String get description => 'Start a new conversation.';

  @override
  Null handle(Agent agent, List<String> args) {
    output.add('Start a new conversation');
    if (output case HtmlNestedSink nested) nested.close();
    agent.startNewConversation();
    return null;
  }
}

class CompactCommand extends Command {
  const CompactCommand(this.output);

  final Sink<String> output;

  @override
  String get name => 'compact';

  @override
  String get description => 'Compact the conversation history.';

  @override
  Null handle(Agent agent, List<String> args) {
    output.add('Compact the conversation history');
    if (output case HtmlNestedSink nested) nested.close();
    agent.compactHistory();
    return null;
  }
}

class HtmlHistoryCommand extends HistoryCommand {
  const HtmlHistoryCommand();

  HtmlHistoryCommand.to(super.output) : super.to();

  @override
  Null handle(Agent agent, List<String> args) {
    super.handle(agent, args);
    if (output case HtmlNestedSink nested) nested.close();
    return null;
  }
}

class HtmlSummarizeCommand extends SummarizeCommand {
  const HtmlSummarizeCommand();

  HtmlSummarizeCommand.to(super.output) : super.to();

  @override
  Future<String?> handle(Agent agent, List<String> args) async {
    await super.handle(agent, args);
    if (output case HtmlNestedSink nested) nested.close();
    return null;
  }
}
