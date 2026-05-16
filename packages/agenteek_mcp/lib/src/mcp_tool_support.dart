import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart' as mcp;

import 'package:agenteek/agenteek.dart';

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
