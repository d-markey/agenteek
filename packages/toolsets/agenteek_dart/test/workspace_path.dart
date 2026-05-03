import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

Future<String> getWorkspacePath(String path) async {
  final uri = Uri.parse('package:agenteek_dart/agenteek_dart.dart');
  final res = File(
    (await Isolate.resolvePackageUri(uri))!.toFilePath(),
  ).parent.parent.absolute;
  return Link(p.join(res.path, '..', '..', '..', path)).absolute.path;
}
