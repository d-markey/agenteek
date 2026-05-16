import 'dart:io';
import 'dart:math';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';
import 'package:agenteek_team/agenteek_team.dart';
import 'package:logging/logging.dart' as l;
import 'package:path/path.dart' as p;

import 'console_sink.dart';
import 'args.dart';

void main(List<String> arguments) async {
  Log.enable();

  l.hierarchicalLoggingEnabled = true;
  l.Logger.root.level = l.Level.SEVERE;
  l.Logger('dartantic.orchestrator').level = l.Level.ALL;
  l.Logger('dartantic.executor.tool').level = l.Level.INFO;
  l.Logger('dartantic.chat_agent').level = l.Level.OFF;
  l.Logger('GoogleAI.HTTP').level = l.Level.SEVERE;
  l.Logger.root.onRecord.listen(_log);

  final args = Args.parse(arguments);
  if (args.teamConfPath.isEmpty) {
    print('Missing team configuration (YAML file)');
    usage();
  } else if (args.promptPath.isNotEmpty) {
    print('Unsupported argument: --prompt:${args.promptPath}');
    usage();
  } else if (args.unknown.isNotEmpty) {
    print('Unknown arguments: ${args.unknown.join(', ')}');
    usage();
  } else if (args.usage) {
    usage();
  }

  // apply defaults and load configuration
  if (p.isRelative(args.teamConfPath)) {
    args.overrideTeamConfPath(
      p.join(p.dirname(Platform.script.toFilePath()), args.teamConfPath),
    );
  }

  File? secretsFile;
  if (args.secretsPath.isEmpty) {
    secretsFile = await FileLocator.find(
      Directory(Platform.script.toFilePath()).parent,
      '.secret.keys',
    );
  } else {
    secretsFile = File(args.secretsPath);
    if (!await secretsFile.exists()) {
      final dir = Directory(args.secretsPath);
      if (!await dir.exists()) {
        throw Exception('Secret keys directory not found: "${dir.path}".');
      }
      secretsFile = await FileLocator.find(dir, '.secret.keys');
    }
  }
  if (secretsFile == null) {
    throw Exception('Could not find ".secret.keys" file.');
  }

  print('Loading secrets from: ${secretsFile.path}');
  final secrets = await Secrets.load(secretsFile.path);

  print('Loading team configuration from: ${args.teamConfPath}');
  final agentsConf = await loadAgentsConf(File(args.teamConfPath), secrets);

  // initialize team from configuration
  final agents = buildTeam(
    agentsConf,
    secrets: secrets,
    getUserInput: () => readMessage('\x1B[42m You \x1B[0m'),
    outputCallbackBuilder: (name) => ConsoleSink('\x1B[43m$name\x1B[0m'),
    a2aSinkBuilder:
        ({required String from, required String to, required String color}) =>
            ConsoleSink('\x1B[${color}m$from => $to\x1B[0m'),
  );

  // the root agent is the only interactive agent
  final rootAgent = agents.values.whereType<InteractiveAgent>().single;

  // TODO: the root agent may summarize his history
  // rootAgent.toolSet.registerAll(
  //   rootAgent.chatManager.getChatTools(
  //     allowResetChat: false,
  //     allowSummarizeChat: true,
  //   ),
  // );

  print(
    'rootAgent = $rootAgent / ${rootAgent.displayName} / tools: ${rootAgent.toolNames.join(', ')}',
  );

  // process user instructions
  await rootAgent.interactWithUser(/*handleUserCommand: userCommandHandler*/);

  print('Shutting down...');
  await Future.wait(agents.values.map((a) => a.dispose()));
  Log.disable();
  print('Done.');
}

Never usage() {
  print(
    'USAGE: agentic_team_cli\n'
    ' [--secrets:<PATH TO THE .secret.keys FILE OR DIRECTORY>]\n'
    ' [--team-conf:<PATH TO THE TEAM\'S YAML CONFIGURATION FILE>]\n'
    ' --help\n'
    '\n',
  );
  exit(1);
}

// console intput / output
String readMessage(String header) {
  stdout.write('$header: ');
  return stdin.readLineSync()?.trim() ?? '';
}

void echoMessage(String header, String message) {
  for (var line in message.split('\n')) {
    stdout.writeln('$header: $line');
  }
}

final sw = Stopwatch()..start();

void _log(l.LogRecord r) {
  if (r.loggerName == 'GoogleAI.HTTP' && r.level < l.Level.SEVERE) return;

  final msg = r.message.toLowerCase();
  if (r.error != null) {
    _logLines(r);
  } else if (r.loggerName.startsWith('dartantic.orchestrator')) {
    if (msg.contains('initializing') ||
        msg.contains('finalizing') ||
        (msg.contains('streaming chunk') && sw.elapsedMilliseconds >= 10000)) {
      _logLines(r);
    }
  } else {
    _logLines(r);
  }
}

void _logLines(l.LogRecord r) {
  final maxLen = l.Level.LEVELS.map((l) => l.name.length).reduce(max);
  final prefix = '[${r.time}] ${r.level.name.padRight(maxLen)} ${r.loggerName}';
  List<String> lines;
  if (r.error == null) {
    lines = r.message.split('\n');
  } else {
    final st = r.stackTrace?.toString();
    lines = 'ERROR: ${r.error}'.split('\n');
    if (st != null) {
      lines.addAll(['CALL STACK:', ...st.split('\n').map((l) => '  $l')]);
    }
  }
  for (var l in lines) {
    print('$prefix> $l');
  }
  sw.reset();
}
