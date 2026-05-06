import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg;
import 'package:path/path.dart' as p;

import 'tools/analyze.dart';
import 'tools/format.dart';
import 'tools/read_pubspec.dart';
import 'tools/pub_get.dart';
import 'tools/run.dart';
import 'tools/test.dart';

class DartToolSet extends ToolSet with Prefix, Scope {
  DartToolSet({
    required String prefix,
    String? scope,
    String root = '.',
    this.allowRun = false,
  }) : prefix = prefix.toLowerCase().trim(),
       scope = scope?.trim() ?? '',
       root = p.canonicalize(root) + Platform.pathSeparator {
    // register tools
    register(readPubspecTool(this));
    register(analyzeTool(this));
    register(formatTool(this));
    register(pubGetTool(this));
    register(testTool(this));
    if (allowRun) register(runTool(this));
  }

  /// used as a namespace for functions
  @override
  final String prefix;

  /// used as a scope description for tools
  @override
  final String scope;

  /// the root folder for this toolset
  final String root;

  final bool allowRun;

  Future<Json> exec(String executable, List<String> args) async {
    final id = Object().hashCode.toRadixString(16).padLeft(8, '0');

    final completer = Completer<Json>();

    dbg.trace('[$id] $executable $args');
    final process = await Process.start(
      executable,
      args,
      workingDirectory: root,
    );

    final stdErr = <List<int>>[], srdErrDone = Completer();
    process.stderr.listen((e) {
      dbg.trace('[$id] [ERR] ${utf8.decode(e)}');
      stdErr.add(e);
    }, onDone: srdErrDone.complete);

    final stdOut = <List<int>>[], stdOutDone = Completer();
    process.stdout.listen((e) {
      dbg.trace(() => '[$id] [OUT] ${utf8.decode(e)}');
      stdOut.add(e);
    }, onDone: stdOutDone.complete);

    process.exitCode.then(
      (exitCode) async {
        await srdErrDone.future;
        await stdOutDone.future;
        completer.complete({
          'commandLine': {'exe': executable, 'args': args},
          'stderr': utf8.decode(stdErr.expand(($) => $).toList()),
          'stdout': utf8.decode(stdOut.expand(($) => $).toList()),
          'exitCode': exitCode,
        });
      },
      onError: (ex) async {
        dbg.error('[$id] $executable $args failed: $ex');
        await srdErrDone.future;
        await stdOutDone.future;
        completer.complete({
          'commandLine': {'exe': executable, 'args': args},
          'exception': ex.toString(),
        });
      },
    );

    return completer.future;
  }
}
