import 'dart:io';

import '../lib/agenteek_containers.dart';

void main() async {
  final version = await PodmanContainer.getVersion();
  print('Podman version --> $version');

  final workspace = File(Platform.script.toFilePath())
      .parent /*example*/
      .parent /*agenteek_container*/
      .parent /*packages*/
      .parent
      .absolute;

  final container = PodmanContainer(image: 'dart:stable');

  print('Start temporary container...');
  await container.start();
  print('Container ${container.id} started.');

  print('Copy $workspace to /sandbox...');
  await container.rmdir('/sandbox');
  await container.cpdir(workspace, '/sandbox');

  print('Check workspace in /sandbox...');
  var res = await container.run('cat pubspec.yml', workingDir: '/sandbox');
  final output = res['stdout']?.toString() ?? '';
  if (!output.contains('workspace:')) {
    print('Repo is not a Dart workspace!');
  }
  if (!output.contains('packages/*')) {
    print('Workspace does not contain `packages/*`!');
  }

  print('Run "dart pub get"...');
  res = await container.run('dart pub get', workingDir: '/sandbox');
  print(res['stdout']);

  print('');
  print('Run "dart test packages/agenteek" in /sandbox...');
  res = await container.run(
    'dart test packages/agenteek',
    workingDir: '/sandbox',
  );
  print(res['stdout']);

  print('');
  print('Run "dart test" in /sandbox/packages/agenteek...');
  res = await container.run(
    'dart test',
    workingDir: '/sandbox/packages/agenteek',
  );
  print(res['stdout']);

  print('Clear /sandbox...');
  await container.rmdir('/sandbox');

  print('Stop container...');
  await container.stop();
  print(
    'Container id=${container.id}, isRunning=${await container.isRunning()}',
  );
}
