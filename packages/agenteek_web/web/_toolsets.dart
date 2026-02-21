import 'package:agenteek/agenteek.dart';
import 'package:better_future/better_future.dart';
import 'package:dart_mcp/client.dart' as mcp;

final deepWikiMcpServer = mcp.Implementation(
  name: 'DeepWiki',
  version: '1.0.0',
);

final context7McpServer = mcp.Implementation(
  name: 'Context7',
  version: '1.0.0',
);

Future<ToolSet> initializeToolSets() async {
  final outcomes = await BetterFuture.settle<ToolSet?>({
    'deepwiki': () => deepWikiMcpServer.setup(
      prefix: 'deepwiki',
      scope: 'DeepWiki information for GitHub repositories',
      url: Uri.parse('https://mcp.deepwiki.com/mcp'),
      toolsAcl: AccessControlList.allowAll,
    ),
    'context7': () => context7McpServer.setup(
      prefix: 'context7',
      scope: 'Context7 library documentation',
      url: Uri.parse('https://mcp.context7.com/mcp'),
      toolsAcl: AccessControlList.allowAll,
    ),
  });

  final failedTools = outcomes.entries
      .where((e) => e.value.isFailure || e.value.result == null)
      .map((e) => e.key);
  for (var failed in failedTools) {
    print('Failed to initialize tools for "$failed".');
  }

  return ToolSet.combined(
    outcomes.values
        .whereType<BetterSuccess<ToolSet?>>()
        .map((v) => v.result)
        .nonNulls,
  );
}
