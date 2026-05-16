import 'dart:async';
import 'dart:convert';

import 'package:agenteek/agenteek.dart';
import 'package:dart_mcp/client.dart' as mcp;
import 'package:logging/logging.dart';

import 'mcp_extension.dart';

const _experimental = true;

class McpToolSet extends ToolSet {
  McpToolSet(this.prefix, this.scope, this._client, this._connection);

  @override
  Logger get logger => Logger('${super.logger.name}.${name.toLowerCase()}');

  final String prefix;
  final String scope;

  static final _unknown = mcp.Implementation(name: '', version: '0.0.0');

  mcp.Implementation get serverInfo => _connection.serverInfo ?? _unknown;
  mcp.Implementation get clientInfo => _client.implementation;

  String get name => (_connection.serverInfo ?? _client.implementation).name;
  String get version =>
      (_connection.serverInfo ?? _client.implementation).version;

  final mcp.MCPClient _client;
  final mcp.ServerConnection _connection;

  Future<void> initialize({
    AccessControlList toolsAcl = AccessControlList.allowAll,
  }) async {
    final initializeResult = await _connection.initialize(
      mcp.InitializeRequest(
        protocolVersion: mcp.ProtocolVersion.latestSupported,
        capabilities: _client.capabilities,
        clientInfo: _client.implementation,
      ),
    );

    // Notify the server that we are initialized.
    _connection.notifyInitialized();

    // Load list of tools.
    if (initializeResult.capabilities.tools != null) {
      final tools = (await _connection.listTools(
        mcp.ListToolsRequest(),
      )).tools.where((tool) => toolsAcl.check(tool.name));
      for (var tool in tools) {
        var description = tool.description ?? '';
        if (scope.isNotEmpty) {
          if (description.isNotEmpty) description += '; ';
          description += '**scope: $scope**';
        }
        final declaration = Tool(
          name: '$prefix.${tool.name}',
          description: description,
          inputSchema: tool.getSchema(),
          onCall: _getHandlerFor(tool),
        );
        register(declaration);
      }
    }
  }

  FutureOr<ToolOutcome> Function(Json) _getHandlerFor(mcp.Tool tool) {
    final name = tool.name;

    return (Json args) async {
      logger.info('Calling tool $name...');
      final res = await _connection.callTool(
        mcp.CallToolRequest(name: name, arguments: args),
      );
      logger.info('Tool $name results: $res');
      if (res.isError == true) return ToolError(res as Json);

      if (_experimental && res.structuredContent != null) {
        final structured = _tryDecode(res.structuredContent);
        if (structured != null) {
          String? table;
          try {
            if (structured case List data) {
              table = MarkdownTable.fromJsonList(data.cast<Json>());
            } else if (structured case {'content': Object? data}) {
              data = _tryDecode(data);
              if (data is List) {
                table = MarkdownTable.fromJsonList(data.cast<Json>());
                structured.remove('content');
                if (structured.isNotEmpty) {
                  table = '${jsonEncode(structured)}\n\n$table';
                }
              }
            }
          } catch (e) {
            logger.warning('Error converting structured content: $e');
          }
          return ToolSuccess(table ?? res);
        }
      }

      return ToolSuccess(res);
    };
  }

  static Object? _tryDecode(Object? data) {
    if (data is String) {
      try {
        data = data.trim().isEmpty ? null : jsonDecode(data);
      } catch (_) {
        try {
          data = (data as String)
              .replaceAll('\\r', '\r')
              .replaceAll('\\n', '\n')
              .replaceAll('\\t', '\t');
          data = jsonDecode(data);
        } catch (_) {}
      }
    }
    return data;
  }

  @override
  Future<void> dispose() async {
    if (!disposed) {
      super.dispose();
      await _connection.shutdown();
      await _client.shutdown();
    }
  }
}
