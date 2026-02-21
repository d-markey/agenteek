import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg show trace;
import 'package:agenteek_cli/agenteek_cli.dart';
import 'package:path/path.dart' as p;

import 'agent_loader.dart';
import 'agent_sink.dart';
import 'args.dart';
import 'team_builder.dart';
import 'user_command_handler.dart';

void main(List<String> arguments) async {
  Log.enable();

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
      p.join(p.dirname(Platform.script.toFilePath()), 'personas_dev_team.yaml'),
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

  final secrets = await InMemorySecrets.load(secretsFile.path);

  final agentsConf = await loadAgentsConf(
    await File(args.teamConfPath).readAsString(),
    secrets,
  );

  // initialize team from configuration
  final agents = buildTeam(
    agentsConf,
    secrets: secrets,
    getUserInput: () => readMessage('\x1B[44mYou\x1B[0m'),
    outputCallbackBuilder: (name) => AgentSink('\x1B[94m$name\x1B[0m'),
    inputCallbackBuilder: (instructorName, name) =>
        AgentSink('\x1B[44m$instructorName => $name\x1B[0m'),
  );

  // the root agent is **LAST** in list
  final rootAgent = agents[agentsConf.last.displayName] as InteractiveAgent;

  // TODO: the root agent may summarize his history
  // rootAgent.toolSet.registerAll(
  //   rootAgent.chatManager.getChatTools(
  //     allowResetChat: false,
  //     allowSummarizeChat: true,
  //   ),
  // );

  dbg.trace(
    'rootAgent = $rootAgent / ${rootAgent.name} / tools: ${rootAgent.toolNames.join(', ')}',
  );

  // process user instructions
  await rootAgent.interactWithUser(userCommandHandler);

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
