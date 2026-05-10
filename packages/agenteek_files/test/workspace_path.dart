import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

Future<String> getWorkspacePath(String path) async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:agenteek/agenteek.dart'),
  );
  final workspace = File(uri!.toFilePath())
      .parent /*agenteek.dart*/
      .parent /*lib*/
      .parent /*agenteek*/
      .parent /*packages*/
      .absolute;
  return Link(p.join(workspace.path, path)).absolute.path;
}
