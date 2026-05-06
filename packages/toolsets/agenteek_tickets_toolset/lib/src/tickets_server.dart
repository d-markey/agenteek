import 'package:agenteek/agenteek.dart';
import 'package:dart_mcp/server.dart' as mcp;

import 'tickets_toolset.dart';

base class TicketsMcpServer extends mcp.MCPServer with mcp.ToolsSupport {
  TicketsMcpServer(
    this.owner,
    this.fileSystem,
    super.channel, {
    super.protocolLogSink,
  }) : super.fromStreamChannel(
         implementation: mcp.Implementation(
           name: 'Ticket Management',
           version: '1.0.0',
         ),
         instructions: 'Handle the creation of tickets',
       ) {
    _toolSet = TicketToolSet(
      owner: owner,
      prefix: 'tickets',
      scope: implementation.name,
      fileSystem: fileSystem,
    );
    registerToolSet(_toolSet);
  }

  final String owner;
  final FileSystem fileSystem;
  late final TicketToolSet _toolSet;
}
