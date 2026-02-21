import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg show trace;
import 'package:agenteek_cli/agenteek_cli.dart';
import 'package:agenteek_files/agenteek_files.dart';
import 'package:path/path.dart' as p;

import 'agent_loader.dart';
import 'agent_sink.dart';
import 'args.dart';
import 'team_builder.dart';

void main(List<String> argumentss) async {
  Log.enable();

  final args = Args.parse(argumentss);

  if (args.promptPath.isEmpty) {
    print('Missing prompt argument.\n\n');
    usage();
  } else if (args.unknown.isNotEmpty) {
    print('Unknown arguments: ${args.unknown.join(', ')}');
    usage();
  } else if (args.usage) {
    usage();
  }

  if (p.isRelative(args.promptPath)) {
    args.overridePromptPath(
      p.join(p.dirname(Platform.script.toFilePath()), args.promptPath),
    );
  }

  final promptFile = File(args.promptPath);
  if (!await promptFile.exists()) {
    print('File "${args.promptPath}" not found.\n\n');
    usage();
  }

  final prompt = await FileReader.readString(promptFile);

  // apply defaults and load configuration
  if (args.teamConfPath.isEmpty) {
    args.overridePromptPath(
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
    outputCallbackBuilder: (name) => AgentSink('\x1B[94m$name\x1B[0m'),
    inputCallbackBuilder: (instructorName, name) =>
        AgentSink('\x1B[44m$instructorName => $name\x1B[0m'),
  );

  // the root agent is **LAST** in list
  final rootAgent = agents[agentsConf.last.displayName] as Agent;

  // TODO: the root agent may summarize his history
  // rootAgent.toolSet.registerAll(
  //   rootAgent.chatManager.getChatTools(
  //     allowResetChat: false,
  //     allowSummarizeChat: true,
  //   ),
  // );

  for (var agent in agents.values) {
    dbg.trace(
      '${agent == rootAgent ? 'rootAgent' : 'agent'} = ${agent.name} / tools: ${agent.toolNames.join(', ')}',
    );
  }

  // process prompt
  final response = await rootAgent.invoke(prompt);
  rootAgent.modelOutput.add(response);

  var done = false;
  while (!done) {
    final checkpoint = rootAgent.getCheckPoint();
    final answer = (await rootAgent.invoke(
      'Are you finished? Answer with a single `Yes` or `No`.',
    )).trim().toLowerCase();
    done = answer.startsWith('yes') || answer.contains('error');
    if (!done) {
      rootAgent.restoreCheckPoint(checkpoint);
      final response = await rootAgent.invoke('Finish the task.');
      rootAgent.modelOutput.add(response);
    }
  }

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
    ' --prompt:<PATH TO THE PROMPT FILE>\n'
    ' --help\n'
    '\n',
  );
  exit(1);
}
