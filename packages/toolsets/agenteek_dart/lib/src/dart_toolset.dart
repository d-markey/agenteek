import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg show trace;
import 'package:agenteek_files/agenteek_files.dart';
import 'package:dartantic_interface/dartantic_interface.dart' as ai_;
import 'package:path/path.dart' as p;

class DartToolSet extends ToolSet {
  DartToolSet({required this.prefix, String root = '.'})
    : root = p.canonicalize(root) + Platform.pathSeparator {
    // register tools
    register(_getPubspecSpec);
    register(_analyzeSpec);
    register(_formatSpec);
  }

  /// used as a namespace for functions
  final String prefix;

  /// the root folder for this toolset
  final String root;

  // get pub spec

  late final ai_.Tool _getPubspecSpec = ai_.Tool(
    name: '${prefix}_get_pubspec',
    description: _scoped('Gets the pubspec file'),
    onCall: (args) async {
      final file = await File('pubspec.yaml').check<File>(root);
      if (!await file.exists()) {
        throw 'Not found: ${file.getPath(root)}';
      }
      return {'content': (await FileReader.readString(file))};
    },
  );

  // analyze

  late final ai_.Tool _analyzeSpec = ai_.Tool(
    name: '${prefix}_analyze',
    description: _scoped('Analyzes a Dart file or directory'),
    inputSchema: z.object(
      {'path': z.string('The path of the file to analyze.')},
      required: ['path'],
    ),
    onCall: (args) async {
      args as Json;
      final fileOrDir = await Link(args['path'] as String).check(root);
      if (!await fileOrDir.exists()) {
        throw 'Not found: ${fileOrDir.getPath(root)}';
      }
      return await _exec('dart', ['analyze', fileOrDir.path]);
    },
  );

  // format

  late final ai_.Tool _formatSpec = ai_.Tool(
    name: '${prefix}_format',
    description: _scoped('Formats a Dart file'),
    inputSchema: z.object(
      {'path': z.string('The path of the file to format.')},
      required: ['path'],
    ),
    onCall: (args) async {
      args as Json;
      final file = await File(args['path'] as String).check(root);
      if (!await file.exists()) {
        throw 'Not found: ${file.getPath(root)}';
      }
      return await _exec('dart', ['format', file.path]);
    },
  );

  // helper methods

  String _scoped(String description) => '$description (root: `$root`).';

  static Future<Json> _exec(String executable, List<String> args) async {
    final id = Object().hashCode.toRadixString(16).padLeft(8, '0');

    final completer = Completer<Json>();

    dbg.trace('[$id] $executable $args');
    final process = await Process.start(executable, args);

    final outputs = <String>[];
    process.stderr.listen((e) {
      final text = utf8.decode(e).trimRight();
      if (text.isNotEmpty) {
        dbg.trace('[$id] [ERR] $text');
        outputs.add('[stderr] $text');
      }
    });

    process.stdout.listen((e) {
      final text = utf8.decode(e).trimRight();
      if (text.isNotEmpty) {
        dbg.trace('[$id] [OUT] $text');
        outputs.add('[stdout] $text');
      }
    });

    process.exitCode.then((exitCode) {
      completer.complete({'output': outputs.join(''), 'exitCode': exitCode});
    });

    return completer.future;
  }
}

extension FileSystemEntityEx on FileSystemEntity {
  /// checks the entity belongs to the root directory
  Future<T> check<T extends FileSystemEntity>(String root) async {
    var resolvedPath = p.canonicalize(p.join(root, path));

    bool isDirectory;
    if (this is Link) {
      final type = await FileSystemEntity.type(resolvedPath, followLinks: true);
      isDirectory = (type == FileSystemEntityType.directory);
    } else {
      isDirectory = this is Directory;
    }

    final local = isDirectory ? Directory(resolvedPath) : File(resolvedPath);
    if (await local.exists()) {
      resolvedPath = p.canonicalize(await local.resolveSymbolicLinks());
    }
    if (isDirectory && !resolvedPath.endsWith(Platform.pathSeparator)) {
      resolvedPath += Platform.pathSeparator;
    }
    if (!resolvedPath.startsWith(root)) throw 'Access denied';
    return (isDirectory ? Directory(resolvedPath) : File(resolvedPath)) as T;
  }

  /// gets the local part of the path under root
  String getPath(String root) =>
      p.canonicalize(absolute.path).substring(root.length);
}
