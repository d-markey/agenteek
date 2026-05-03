import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg;
import 'package:agenteek_cli/agenteek_cli.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart' as l;

import 'console_sink.dart';
import 'args.dart';

final sw = Stopwatch()..start();
var lastTimestamp = 0;

void _log(l.LogRecord r) {
  final msg = r.message.toLowerCase();
  if (r.error != null) {
    lastTimestamp = sw.elapsedMilliseconds;
    print(
      '${r.level} ${r.time} ${r.loggerName} ${r.message} ${r.error} ${r.stackTrace}',
    );
  } else if (msg.contains('initializing') || msg.contains('finalizing')) {
    lastTimestamp = sw.elapsedMilliseconds;
    print('${r.level} ${r.time} ${r.loggerName} ${r.message}');
  } else if (msg.contains('tool')) {
    lastTimestamp = sw.elapsedMilliseconds;
    print('${r.level} ${r.time} ${r.loggerName} ${r.message}');
  } else {
    final dt = sw.elapsedMilliseconds - lastTimestamp;
    if (dt < const Duration(seconds: 15).inMilliseconds) return;
    lastTimestamp = sw.elapsedMilliseconds;
    print('${r.level} ${r.time} ${r.loggerName} ${r.message}');
  }
}

void main(List<String> arguments) async {
  Log.enable();

  l.hierarchicalLoggingEnabled = true;
  l.Logger('dartantic.orchestrator')
    ..level = l.Level.ALL
    ..onRecord.listen(_log);
  l.Logger('dartantic.chat_agent')
    ..level = l.Level.ALL
    ..onRecord.listen(_log);

  final args = Args.parse(arguments);
  if (args.promptPath.isNotEmpty) {
    print('Unsupported argument: --prompt:${args.promptPath}');
    usage();
  } else if (args.unknown.isNotEmpty) {
    print('Unknown arguments: ${args.unknown.join(', ')}');
    usage();
  } else if (args.usage) {
    usage();
  }

  // apply defaults and load configuration
  if (args.teamConfPath.isEmpty) {
    args.overrideTeamConfPath(
      p.join(p.dirname(Platform.script.toFilePath()), 'lgmodel/team.yaml'),
    );
  } else if (p.isRelative(args.teamConfPath)) {
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
    getUserInput: () => readMessage('\x1B[44mYou\x1B[0m'),
    outputCallbackBuilder: (name) => ConsoleSink('\x1B[94m$name\x1B[0m'),
    inputCallbackBuilder: (instructorName, name) =>
        ConsoleSink('\x1B[44m$instructorName => $name\x1B[0m'),
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

  dbg.trace(
    'rootAgent = $rootAgent / ${rootAgent.displayName} / tools: ${rootAgent.toolNames.join(', ')}',
  );

  // process user instructions
  await rootAgent.interactWithUser(/*handleUserCommand: userCommandHandler*/);

  dbg.trace('Shutting down...');
  await Future.wait(agents.values.map((a) => a.dispose()));
  Log.disable();
  dbg.trace('Done.');
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
