import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agenteek/agenteek.dart';
import 'package:logging/logging.dart';

import 'container.dart';

class PodmanContainer implements Container {
  PodmanContainer({required this.image, String name = ''}) : name = name.trim();

  static Logger get _logger => Logger('agenteek.containers.podman');

  @override
  final String image; // dart:stable

  @override
  final String name;

  @override
  String get id => name.isNotEmpty ? name : _id;

  String _id = '';

  static Future<bool> ensureMachineIsRunning() async {
    try {
      await _exec('machine', ['start']);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> getVersion() async {
    try {
      final res = await _exec('--version');
      final output = res['stdout']?.toString() ?? '';
      final version = RegExp('\\d+\\.\\d+\\.\\d+').firstMatch(output)?.group(0);
      return version ?? '';
    } catch (ex, st) {
      print('PODMAN ERROR $ex\n$st');
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
  Future<Json> run(
    String command, {
    String? workingDir,
    Duration? timeout,
  }) async {
    final sw = Stopwatch()..start();
    final timer = Timer.periodic(const Duration(seconds: 30), (t) {
      _logger.fine(
        '[${sw.elapsed}] Command "$command" still pending in container $id...',
      );
    });

    try {
      return await _run(command, workingDir: workingDir, timeOut: timeout);
    } finally {
      timer.cancel();
    }
  }

  Future<Json> _run(
    String command, {
    String? workingDir,
    Duration? timeOut,
  }) async {
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
    ], timeOut);
  }

  static Future<Json> _exec(
    String command, [
    List<String> args = const [],
    Duration? timeOut,
  ]) async {
    final id = Object().hashCode.toRadixString(16).padLeft(8, '0');

    final completer = Completer<Json>();

    final sw = Stopwatch()..start();

    _logger.fine('[$id] podman $command $args');
    final process = await Process.start('podman', [command, ...args]);

    final stdErr = BytesBuilder(), stdErrDone = Completer();
    process.stderr.listen((e) {
      _logger.warning('[$id] [ERR] ${utf8.decode(e)}');
      stdErr.add(e);
    }, onDone: stdErrDone.safeComplete);

    final stdOut = BytesBuilder(), stdOutDone = Completer();
    process.stdout.listen((e) {
      _logger.fine(() => '[$id] [OUT] ${utf8.decode(e)}');
      stdOut.add(e);
    }, onDone: stdOutDone.safeComplete);

    Timer? timeoutTimer;
    if (timeOut != null) {
      timeoutTimer = Timer(timeOut, () {
        final elapsed = sw.elapsed;
        completer.safeComplete({
          'commandLine': {'command': command, 'args': args},
          'stderr': utf8.decode(stdErr.toBytes()),
          'stdout': utf8.decode(stdOut.toBytes()),
          'exitCode': null,
          'elapsed': elapsed.inMilliseconds > 10000
              ? '${elapsed.inSeconds} seconds'
              : '${elapsed.inMilliseconds} milliseconds',
          'status':
              'The command timed-out after $timeOut.'
              '`stderr` and `stdout` content are provided but likely incomplete.',
        });
        process.kill();
        unawaited(Future.wait([stdErrDone.future, stdOutDone.future]));
      });
    }

    process.exitCode.then((exitCode) async {
      timeoutTimer?.cancel();
      final elapsed = sw.elapsed;
      await Future.wait([stdErrDone.future, stdOutDone.future]);
      completer.safeComplete({
        'commandLine': {'command': command, 'args': args},
        'stderr': utf8.decode(stdErr.toBytes()),
        'stdout': utf8.decode(stdOut.toBytes()),
        'elapsed': elapsed.inMilliseconds > 10000
            ? '${elapsed.inSeconds} seconds'
            : '${elapsed.inMilliseconds} milliseconds',
        'exitCode': exitCode,
      });
    }, onError: completer.safeCompleteError);

    return completer.future;
  }
}

extension<T> on Completer<T> {
  void safeComplete([FutureOr<T>? value]) {
    if (!isCompleted) complete(value);
  }

  void safeCompleteError(Object error, StackTrace st) {
    if (!isCompleted) completeError(error, st);
  }
}
