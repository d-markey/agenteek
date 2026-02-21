import 'dart:async';

import 'package:dart_mcp/client.dart' as mcp;
import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '../../utils/access_control_list.dart';
import '../../utils/debug.dart' as dbg;
import '../../utils/types.dart';
import '../../utils/zod.dart';
import '../toolset.dart';

class McpToolSet extends ToolSet {
  McpToolSet(this.prefix, this.scope, this._client, this._connection);

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
        final declaration = dartantic.Tool(
          name: '${prefix}_${tool.name}',
          description: description,
          inputSchema: z.of(tool),
          onCall: _getHandlerFor(tool),
        );
        register(declaration);
      }
    }
  }

  JsonToolFunction _getHandlerFor(mcp.Tool tool) {
    final name = tool.name;

    return (args) async {
      try {
        final res = await _connection.callTool(
          mcp.CallToolRequest(name: name, arguments: args),
        );
        return res as Json;
      } catch (ex, st) {
        final message = 'Error executing $name: $ex\nStacktrace: $st';
        dbg.trace(message);
        return {'error': message, 'stacktrace': st.toString()};
      }
    };
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
