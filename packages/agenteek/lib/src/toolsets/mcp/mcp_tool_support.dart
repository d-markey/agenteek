import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/client.dart' as mcp;
import 'package:dart_mcp/server.dart' as mcp;

import '../../channels/http_channel.dart';
import '../../utils/access_control_list.dart';
import '../tool.dart';
import '../toolset.dart';
import 'mcp_toolset.dart';

extension McpToolSetExt on mcp.Implementation {
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

extension ToolSupportExt on mcp.ToolsSupport {
  void registerToolSet(ToolSet toolSet) {
    for (var toolName in toolSet.names) {
      final tool = toolSet.getTool(toolName)!;
      registerTool(
        mcp.Tool(
          name: toolName,
          description: tool.description,
          inputSchema: mcp.ObjectSchema.fromMap(tool.inputSchema.value),
        ),
        _wrapToolHandler(tool),
      );
    }
  }
}

Future<mcp.CallToolResult> Function(mcp.CallToolRequest) _wrapToolHandler(
  Tool tool,
) => (mcp.CallToolRequest req) async {
  try {
    final res = await tool.call(req.arguments ?? const {});
    return _wrapToolResult(res);
  } catch (ex) {
    return _wrapToolError(ex);
  }
};

mcp.CallToolResult _wrapToolResult(dynamic result) => mcp.CallToolResult(
  content: [
    mcp.Content.text(
      text: _isJsonStructure(result) ? jsonEncode(result) : result.toString(),
    ),
  ],
);

mcp.CallToolResult _wrapToolError(Object error) => mcp.CallToolResult(
  content: [mcp.Content.text(text: '**ERROR**: $error')],
  isError: true,
);

bool _isJsonStructure(dynamic data) {
  if (data is Map) {
    if (data.keys.any((k) => k is! String)) return false;
    return data.values.every(_isJson);
  } else if (data is List) {
    return data.every(_isJson);
  } else {
    return false;
  }
}

bool _isJson(dynamic data) {
  if (data == null) return true;
  if (data is String) return true;
  if (data is bool) return true;
  if (data is num) return true;
  if (data is List) return _isJsonStructure(data);
  if (data is Map) return _isJsonStructure(data);
  return false;
}
