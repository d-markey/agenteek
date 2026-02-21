import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg show trace;
import 'package:dart_mcp/client.dart';

import 'mcp_arithmetic.dart' as mcp;

typedef McpConnectedClient = ({MCPClient client, ServerConnection connection});

Future<McpConnectedClient> initializeArithmeticMcpServerAndClient() async {
  final process = await Process.start('dart', [
    'run',
    'bin/calc/mcp_arithmetic.dart',
  ]);

  final client = MCPClient(mcp.impl);
  final connection = client.connectServer(
    stdioChannel(input: process.stdout, output: process.stdin),
  );

  process.stderr.listen((e) {
    final text = utf8.decode(e).trimRight();
    if (text.isNotEmpty) dbg.trace('[MCP/${connection.name}] $text');
  });

  unawaited(
    connection.done.then((_) {
      dbg.trace('[MCP/${connection.name}] Terminating server');
      process.kill();
    }),
  );

  return (client: client, connection: connection);
}
