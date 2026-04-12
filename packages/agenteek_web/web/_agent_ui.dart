import 'dart:async';
import 'dart:js_interop';

import 'package:agenteek/agenteek.dart';
import 'package:web/web.dart' as web;

import '_agent_config.dart';
import 'config/build_config.dart';
import 'config/config_store.dart';
import 'config/agent_config_data.dart';
import 'config/model_info_data.dart';
import 'config/custom_mcp_data.dart';
import 'dialog/dialog.dart';
import 'dialog/dialog_field_type.dart';
import '_export_pdf.dart';
import '_html_sink.dart';
import '_user_command_handler.dart';

class AgentUI {
  AgentUI(this.conversationManager) {
    _toggleLogBtn = _getElementById<web.HTMLInputElement>('logToggle');
    _exportPdfBtn = _getElementById<web.HTMLButtonElement>('exportPdf');
    _messages = _getElementById<web.HTMLDivElement>('messages');
    _outputController = HtmlOutputController(_messages);
    _prompt = _getElementById<web.HTMLTextAreaElement>('composer');
    _sendBtn = _getElementById<web.HTMLButtonElement>('send');
    _configModelBtn = _getElementById<web.HTMLButtonElement>('configModel');

    _toggleLogBtn.checked = Log.enabled;
    _toggleLogBtn.onchange = _onToggleLogClick.toJS;
    _exportPdfBtn.onclick = _onExportPdfClick.toJS;
    _configModelBtn.onclick = (web.Event e) {
      reconfigureAgent();
    }.toJS;

    // prepare sinks for display
    userOutput = HtmlSink(_outputController, 'YOU', 'human');
    modelOutput = HtmlSink(
      _outputController,
      () => _current?.agentConfiguration.displayName ?? 'WEB AGENT',
      'agent',
    );
    modelStreamOutput = HtmlStreamingSink(
      _outputController,
      () =>
          '${_current?.agentConfiguration.displayName ?? 'WEB AGENT'} (working)',
      'agent',
    );
    modelThinkingStreamOutput = HtmlStreamingSink(
      _outputController,
      () =>
          '${_current?.agentConfiguration.displayName ?? 'WEB AGENT'} (thinking)',
      'agent',
      collapsible: true,
    );
    systemOutput = HtmlSink(_outputController, 'SYSTEM', 'system');

    if (BuildConfig.withAutoConf) {
      final toolbar = _getElementById<web.HTMLDivElement>('toolbar');
      final autoConfBtn = web.HTMLButtonElement()
        ..innerText = 'Auto Configure'
        ..className = 'button accent'
        ..title = "Auto-Configure Agent"
        ..ariaLabel = "Auto-Configure Agent"
        ..onclick = (web.Event e) {
          ConfigStore.autoConf(Uri.parse('autoconf.json'))
              .then((conf) {
                if (conf == null) {
                  _agentConfCtrlr.add(null);
                } else {
                  _notifyAgentConfig(conf);
                }
              })
              .catchError((ex, st) {
                systemOutput.add('Failed to auto configure: $ex');
                print('$ex @ $st');
                _agentConfCtrlr.add(null);
              });
        }.toJS;
      toolbar.appendChild(autoConfBtn);
    }

    // bind user input and command handler
    userInput = bindUserInput();
    userCommandHandler = bindUserCommandHandler();
  }

  final ConversationManager conversationManager;

  late final HtmlSink userOutput;
  late final HtmlSink modelOutput;
  late final HtmlStreamingSink modelStreamOutput;
  late final HtmlStreamingSink modelThinkingStreamOutput;
  late final HtmlSink systemOutput;

  late final web.HTMLInputElement _toggleLogBtn;
  late final web.HTMLButtonElement _exportPdfBtn;
  late final web.HTMLButtonElement _sendBtn;
  late final web.HTMLButtonElement _configModelBtn;

  late final web.HTMLDivElement _messages;
  late final HtmlOutputController _outputController;
  late final web.HTMLTextAreaElement _prompt;

  late final FutureOr<String> Function() userInput;
  late final UserCommandHandler userCommandHandler;

  final _agentConfCtrlr = StreamController<WebAgentConfig?>();
  Stream<WebAgentConfig?> get agentConfiguration => _agentConfCtrlr.stream;
  WebAgentConfig? _current;

  void clearMessages() {
    _outputController.clear();
  }

  void shutdown() {
    _toggleLogBtn.onchange = null;
    _toggleLogBtn.disabled = true;

    _configModelBtn.onclick = null;
    _configModelBtn.disabled = true;

    _prompt.disabled = true;

    _sendBtn.onclick = null;
    _sendBtn.disabled = true;
  }

  void _onToggleLogClick(web.Event e) {
    if (_toggleLogBtn.checked) {
      Log.enable();
    } else {
      Log.disable();
    }
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

  void _notifyAgentConfig(AgentConfigData config) {
    final secrets = InMemorySecrets({
      '--api-key': config.modelInfo.apiKey,
      '--gh-pat': config.githubPat,
      if (BuildConfig.withCustomMcp)
        for (final mcp in config.authMcpServers) '--${mcp.id}': mcp.authToken,
    });

    final conf = _current = WebAgentConfig(
      agentConfiguration: AgentConfiguration(
        modelInfo: config.modelInfo.id,
        apiKeyName: '--api-key',
        displayName: 'Web Agent (${config.modelInfo.id})',
        secrets: secrets,
      ),
      secrets: secrets,
    );

    _agentConfCtrlr.add(conf);
  }

  Future<void> initializeAgent() async {
    final config = await ConfigStore.load().catchError((ex, st) {
      systemOutput.add('Failed to initialize agent: $ex');
      print('$ex @ $st');
      return null;
    });

    if (config == null || !config.modelInfo.isSet) {
      await reconfigureAgent();
    } else {
      _notifyAgentConfig(config);
    }
  }

  Future<void> reconfigureAgent() async {
    final result = await ModalDialog.show(
      DialogConfig(
        title: 'Configure Agent',
        fields: [
          DialogComplexField(
            label: 'Model Info',
            key: AgentConfigData.kModelInfo,
            isFixed: true,
            items: [
              DialogComplexInputItem(
                label: 'Model ID',
                key: ModelInfoData.kId,
                initialValues: [ConfigStore.current.modelInfo.id],
                placeholder: 'gemini',
              ),
              DialogComplexInputItem(
                label: 'API Key',
                key: ModelInfoData.kApiKey,
                type: DialogFieldType.password,
                initialValues: [ConfigStore.current.modelInfo.apiKey],
                placeholder: 'Enter your API key...',
              ),
            ],
          ),
          DialogField(
            label: 'GitHub PAT:',
            key: AgentConfigData.kGithubPat,
            type: DialogFieldType.password,
            initialValue: ConfigStore.current.githubPat,
            placeholder: 'ghp_...',
          ),
          if (BuildConfig.withCustomMcp)
            DialogComplexField(
              label: 'Custom MCP Servers',
              key: AgentConfigData.kCustomMcp,
              items: [
                DialogComplexInputItem(
                  label: 'Name',
                  key: CustomMcpData.kName,
                  type: DialogFieldType.text,
                  initialValues: ConfigStore.current.mcpServers
                      .map((m) => m.name)
                      .toList(),
                  placeholder: 'My Custom MCP Server',
                ),
                DialogComplexInputItem(
                  label: 'URL',
                  key: CustomMcpData.kUrl,
                  type: DialogFieldType.text,
                  initialValues: ConfigStore.current.mcpServers
                      .map((m) => m.url)
                      .toList(),
                  placeholder: 'http://localhost:8000',
                ),
                DialogComplexDropdownItem(
                  label: 'Auth Header',
                  key: CustomMcpData.kAuthHeader,
                  options: const ['', 'Authorization', 'X-Api-Key', 'X-Token'],
                  initialValues: ConfigStore.current.mcpServers
                      .map((m) => m.authHeader)
                      .toList(),
                ),
                DialogComplexInputItem(
                  label: 'Auth',
                  key: CustomMcpData.kAuthToken,
                  type: DialogFieldType.password,
                  initialValues: ConfigStore.current.mcpServers
                      .map((m) => m.authToken)
                      .toList(),
                  placeholder: 'API key / token',
                ),
              ],
            ),
        ],
      ),
    );

    if (result == null) {
      _agentConfCtrlr.add(null);
    } else {
      await ConfigStore.save(config: result).catchError((ex, st) {
        systemOutput.add('Failed to save config: $ex');
        print('$ex @ $st');
      });

      if (!ConfigStore.current.modelInfo.isSet) {
        _agentConfCtrlr.add(null);
      } else {
        _notifyAgentConfig(ConfigStore.current);
      }
    }
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

  UserCommandHandler bindUserCommandHandler() => (label, args) {
    switch (label.toLowerCase()) {
      case 'exit':
      case 'quit':
      case 'q':
      case 'x':
        return QuitCommand(
          callback: () {
            _agentConfCtrlr.close();
          },
        );

      case 'help':
      case 'h':
      case '?':
        return HelpCommand.to(systemOutput);

      case 'tools':
        return ToolsCommand.to(systemOutput);

      case 'history':
        return HtmlHistoryCommand.to(systemOutput.nested);

      case 'summarize':
      case 'sum':
        return HtmlSummarizeCommand.to(systemOutput.nested);

      case 'systemprompt':
      case 'system-prompt':
      case 'system':
        return SystemPromptCommand.to(systemOutput);

      case 'new':
        return NewConversationCommand(systemOutput);

      default:
        return null;
    }
  };
}

T _getElementById<T extends web.HTMLElement>(String id) =>
    web.document.getElementById(id) as T;
