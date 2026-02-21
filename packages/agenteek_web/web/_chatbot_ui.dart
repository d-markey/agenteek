import 'dart:async';
import 'dart:js_interop';

import 'package:agenteek/agenteek.dart';
import 'package:web/web.dart' as web;

import '_export_pdf.dart';
import '_html_sink.dart';
import '_user_command_handler.dart';

class ChatbotUI {
  ChatbotUI(this.conversationManager) {
    _toggleLogBtn = _getElementById<web.HTMLInputElement>('logToggle');
    _exportPdfBtn = _getElementById<web.HTMLButtonElement>('exportPdf');
    _messages = _getElementById<web.HTMLDivElement>('messages');
    _prompt = _getElementById<web.HTMLTextAreaElement>('composer');
    _sendBtn = _getElementById<web.HTMLButtonElement>('send');
    _setModelInfoBtn = _getElementById<web.HTMLButtonElement>('setModelInfo');

    _toggleLogBtn.checked = Log.enabled;
    _toggleLogBtn.onchange = _onToggleLogClick.toJS;
    _exportPdfBtn.onclick = _onExportPdfClick.toJS;
    _setModelInfoBtn.onclick = _onSetModelInfoClick.toJS;

    // prepare sinks for display
    userOutput = HtmlSink(_messages, 'YOU', 'human');
    modelOutput = HtmlSink(
      _messages,
      () => _current?.displayName ?? 'WEB AGENT',
      'agent',
    );
    systemOutput = HtmlSink(_messages, 'SYSTEM', 'system');

    // bind user input and command handler
    userInput = bindUserInput();
    userCommandHandler = bindUserCommandHandler();
  }

  final ConversationManager conversationManager;

  late final HtmlSink userOutput;
  late final HtmlSink modelOutput;
  late final HtmlSink systemOutput;

  late final web.HTMLInputElement _toggleLogBtn;
  late final web.HTMLButtonElement _exportPdfBtn;
  late final web.HTMLButtonElement _sendBtn;
  late final web.HTMLButtonElement _setModelInfoBtn;

  late final web.HTMLDivElement _messages;
  late final web.HTMLTextAreaElement _prompt;

  late final FutureOr<String> Function() userInput;
  late final Command? Function(String) userCommandHandler;

  final _agentConfCtrlr = StreamController<AgentConfiguration>();
  Stream<AgentConfiguration> get agentConfiguration => _agentConfCtrlr.stream;
  AgentConfiguration? _current;

  Future<String> getImagingApiKey() {
    final completer = Completer<String>();

    var apiKey = '';
    while (apiKey.isEmpty) {
      apiKey =
          web.window
              .prompt('Please provide your CAST Imaging API key:')
              ?.trim() ??
          '';
    }
    completer.complete(apiKey);

    return completer.future;
  }

  void clearMessages() {
    _messages.innerHTML = ''.toJS;
    _messages.scrollTop = 0;
  }

  void shutdown() {
    _toggleLogBtn.onchange = null;
    _toggleLogBtn.disabled = true;

    final modelIdTxt = _getElementById<web.HTMLInputElement>('model_id');
    modelIdTxt.value = '';
    modelIdTxt.disabled = true;

    final apiKeyTxt = _getElementById<web.HTMLInputElement>('api_key');
    apiKeyTxt.value = '';
    apiKeyTxt.disabled = true;

    _setModelInfoBtn.onclick = null;
    _setModelInfoBtn.disabled = true;

    _prompt.disabled = true;

    _sendBtn.onclick = null;
    _sendBtn.disabled = true;
  }

  void _onToggleLogClick(web.Event e) {
    if (Log.enabled) {
      Log.enable();
    } else {
      Log.disable();
    }
    _toggleLogBtn.checked = Log.enabled;
  }

  void _onExportPdfClick(web.Event e) {
    if (conversationManager.history.isNotEmpty) {
      _exportPdfBtn.disabled = true;
      final html = _exportPdfBtn.innerHTML;
      _exportPdfBtn.innerText = 'Generating...';
      exportConversationToPdf(conversationManager.history).whenComplete(() {
        _exportPdfBtn.innerHTML = html;
        _exportPdfBtn.disabled = false;
      });
    }
  }

  void _onSetModelInfoClick(web.Event e) {
    final modelIdTxt = _getElementById<web.HTMLInputElement>('model_id');
    final modelId = modelIdTxt.value.trim();

    final apiKeyTxt = _getElementById<web.HTMLInputElement>('api_key');
    final apiKey = apiKeyTxt.value.trim();

    if (apiKey.length > 6) {
      apiKeyTxt.value =
          apiKey.substring(0, 3) +
          '*' * (apiKey.length - 6) +
          apiKey.substring(apiKey.length - 3);
    } else {
      apiKeyTxt.value = '***';
    }

    final secrets = InMemorySecrets({'--api-key': apiKey});

    final conf = _current = AgentConfiguration(
      modelInfo: modelId,
      apiKeyName: '--api-key',
      displayName: 'Web Agent ($modelId)',
      secrets: secrets,
    );

    _agentConfCtrlr.add(conf);
  }

  PromptCallback bindUserInput() => () {
    final completer = Completer<String>();

    _prompt.disabled = false;
    _prompt.focus();

    _sendBtn.onclick = (web.Event e) {
      final userInput = _prompt.value.trim();
      if (userInput.isNotEmpty) {
        userOutput.add(userInput);
        _prompt.value = '';
        _prompt.disabled = true;
        _sendBtn.disabled = true;
        _sendBtn.onclick = null;
        completer.complete(userInput);
      }
    }.toJS;
    _sendBtn.disabled = false;

    return completer.future;
  };

  Command? Function(String) bindUserCommandHandler() => (command) {
    switch (command.toLowerCase()) {
      case '/exit':
      case '/quit':
      case '/q':
      case '/x':
        return QuitCommand(
          callback: () {
            _agentConfCtrlr.close();
          },
        );

      case '/help':
      case '/h':
      case '/?':
        return HelpCommand.to(systemOutput);

      case '/tools':
        return ToolsCommand.to(systemOutput);

      case '/history':
        return HtmlHistoryCommand.to(systemOutput.nested);

      case '/summarize':
        return HtmlSummarizeCommand.to(systemOutput.nested);

      case '/systemprompt':
      case '/system-prompt':
        return SystemPromptCommand.to(systemOutput);

      case '/new':
        return NewConversationCommand(systemOutput);

      default:
        return null;
    }
  };
}

T _getElementById<T extends web.HTMLElement>(String id) =>
    web.document.getElementById(id) as T;
