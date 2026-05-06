import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:agenteek/agenteek_dbg.dart' as dbg;

import 'container.dart';

class PodmanContainer implements Container {
  PodmanContainer({required this.image, String name = ''}) : name = name.trim();

  @override
  final String image; // dart:stable

  @override
  final String name;

  @override
  String get id => name.isNotEmpty ? name : _id;

  String _id = '';

  static Future<void> startMachine() async {
    try {
      await _exec('machine', ['start']);
    } catch (_) {}
  }

  static Future<String> getVersion() async {
    try {
      final res = await _exec('--version');
      final output = res['stdout']?.toString() ?? '';
      final version = RegExp('\\d+\\.\\d+\\.\\d+').firstMatch(output)?.group(0);
      return version ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<bool?> isRunning() async {
    if (id.isEmpty) return null;

    final res = await _exec('ps', [
      '-a',
      '--format=json',
      name.isNotEmpty ? '--filter=name=$name' : '--filter=id=$_id',
    ]);

    final data = jsonDecode(res['stdout']?.toString() ?? '[]') as List;
    if (data.isEmpty) return null;

    final state = data.first['State']?.toString().toLowerCase().trim() ?? '';
    if (state.contains('running')) return true;

    final status = data.first['Status']?.toString().toLowerCase().trim() ?? '';
    if (status.startsWith('up ')) return true;

    return false;
  }

  @override
  Future<void> create() async {
    var running = await isRunning();
    if (running != null) return;

    final res = await _exec('create', [
      if (name.isNotEmpty) '--name=$name',
      image,
      ...['tail', '-f', '/dev/null'],
    ]);
    final output = res['stdout']?.toString().trim() ?? '';
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(output)) {
      throw Exception('Failed to create container: "$output"');
    }
    _id = output;
  }

  @override
  Future<void> delete() async {
    var running = await isRunning();
    if (running == null) return;
    if (running) await stop();
    await _exec('rm', [id]);
    _id = '';
  }

  @override
  Future<void> start() async {
    var running = await isRunning();

    if (running == null) {
      // create
      await create();
      running = false;
    }

    if (!running) {
      // start
      final res = await _exec('start', [name.isEmpty ? _id : name]);
      final output = res['stdout']?.toString().trim() ?? '';
      if (output != id) {
        throw Exception('Failed to start container: "$output"');
      }
    }
  }

  @override
  Future<void> stop() async {
    if (id.isEmpty) return;
    await _exec('stop', [id]);
    if (name.isEmpty) await delete();
  }

  static String _getSafePath(String dest) {
    dest = dest.trim();
    if (dest.isEmpty) {
      throw ArgumentError('The destination path is empty.');
    }
    if (dest.contains('"')) {
      throw ArgumentError(
        'The destination path contains invalid characters: ".',
      );
    }
    if (!dest.startsWith('/')) dest = '/$dest';
    return dest;
  }

  @override
  Future<void> rmdir(String dest) async {
    dest = _getSafePath(dest);
    await start();
    await _exec('exec', [id, 'sh', '-c', 'rm -rf "$dest"']);
  }

  @override
  Future<void> cpdir(Directory source, String dest) async {
    dest = _getSafePath(dest);
    await start();
    await _exec('cp', [source.absolute.path, '$id:$dest']);
  }

  @override
  Future<Map<String, Object?>> run(String command, {String? workingDir}) async {
    if (workingDir != null) {
      workingDir = _getSafePath(workingDir);
    }
    await start();
    return await _exec('exec', [
      if (workingDir != null) '--workdir=$workingDir',
      id,
      'sh',
      '-c',
      command,
    ]);
  }

  static Future<Map<String, Object?>> _exec(
    String command, [
    List<String> args = const [],
  ]) async {
    final id = Object().hashCode.toRadixString(16).padLeft(8, '0');

    final completer = Completer<Map<String, Object?>>();

    dbg.trace('[$id] podman $command $args');
    final process = await Process.start('podman', [command, ...args]);

    final stdErr = BytesBuilder(), stdErrDone = Completer();
    process.stderr.listen((e) {
      dbg.trace('[$id] [ERR] ${utf8.decode(e)}');
      stdErr.add(e);
    }, onDone: stdErrDone.complete);

    final stdOut = BytesBuilder(), stdOutDone = Completer();
    process.stdout.listen((e) {
      dbg.trace(() => '[$id] [OUT] ${utf8.decode(e)}');
      stdOut.add(e);
    }, onDone: stdOutDone.complete);

    process.exitCode.then((exitCode) async {
      await Future.wait([stdErrDone.future, stdOutDone.future]);
      completer.complete({
        'commandLine': {'command': command, 'args': args},
        'stderr': utf8.decode(stdErr.toBytes()),
        'stdout': utf8.decode(stdOut.toBytes()),
        'exitCode': exitCode,
      });
    }, onError: completer.completeError);

    return completer.future;
  }
}
