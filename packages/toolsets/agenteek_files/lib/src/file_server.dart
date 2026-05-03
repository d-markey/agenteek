import 'package:agenteek/agenteek.dart';
import 'package:dart_mcp/server.dart' as mcp;
import 'package:path/path.dart' as p;

import 'file_toolset.dart';

base class FilesMcpServer extends mcp.MCPServer with mcp.ToolsSupport {
  FilesMcpServer(
    String prefix,
    this.fileSystem,
    super.channel, {
    super.protocolLogSink,
  }) : super.fromStreamChannel(
         implementation: mcp.Implementation(
           name: 'Source File Management',
           version: '1.0.0',
         ),
         instructions: 'Handle source files',
       ) {
    _toolSet = FileToolSet(
      prefix: prefix,
      scope: 'file system for ${p.basename(fileSystem.root)}',
      root: fileSystem.root,
    );
    registerToolSet(_toolSet);
  }

  final FileSystem fileSystem;
  late final FileToolSet _toolSet;
}
