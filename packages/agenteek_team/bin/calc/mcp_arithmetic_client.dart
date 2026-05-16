import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart' as mcp;
import 'package:dart_mcp/stdio.dart';

import 'mcp_arithmetic.dart' as mcp;

typedef McpConnectedClient = ({
  mcp.MCPClient client,
  mcp.ServerConnection connection,
});

Future<McpConnectedClient> initializeArithmeticMcpServerAndClient() async {
  final process = await Process.start('dart', [
    'run',
    'bin/calc/mcp_arithmetic.dart',
  ]);

  final client = mcp.MCPClient(mcp.impl);
  final connection = client.connectServer(
    stdioChannel(input: process.stdout, output: process.stdin),
  );

  process.stderr.listen((e) {
    final text = utf8.decode(e).trimRight();
    if (text.isNotEmpty) print('[MCP/${connection.name}] $text');
  });

  unawaited(
    connection.done.then((_) {
      print('[MCP/${connection.name}] Terminating server');
      process.kill();
    }),
  );

  return (client: client, connection: connection);
}
