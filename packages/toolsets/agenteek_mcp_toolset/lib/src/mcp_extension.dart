import 'dart:async';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_mcp/agenteek_mcp.dart';
import 'package:dart_mcp/client.dart' as mcp;
import 'package:dartantic_interface/dartantic_interface.dart' as dartantic;

import 'mcp_toolset.dart';

extension McpSetupExt on mcp.Implementation {
  Future<McpToolSet?> setup({
    required String prefix,
    required String scope,
    required Uri url,
    Map<String, String>? headers,
    AccessControlList toolsAcl = AccessControlList.allowAll,
  }) async {
    try {
      final client = mcp.MCPClient(this);
      final channel = HttpChannel(url: url, headers: headers);
      final connection = client.connectServer(channel);
      final mcpToolset = McpToolSet(prefix, scope, client, connection);
      await mcpToolset.initialize(toolsAcl: toolsAcl);
      return mcpToolset;
    } catch (ex) {
      print('Failed to initialize MCP server: $ex');
      return null;
    }
  }
}

extension SchemaExt on mcp.Tool {
  dartantic.Schema getSchema() =>
      .fromMap(_removeEmptyEnums(inputSchema as Map<String, Object?>));

  static Map<String, Object?> _removeEmptyEnums(Map<String, Object?> schema) {
    var enums = schema['enum'];
    if (enums is List) {
      if (enums.where((e) => e.toString().trim().isEmpty).isNotEmpty) {
        schema['enum'] = enums
            .where((e) => e.toString().trim().isNotEmpty)
            .toList();
      }
    }
    for (var value in schema.values.whereType<Map>()) {
      _removeEmptyEnums(value as Map<String, Object?>);
    }
    return schema;
  }
}
