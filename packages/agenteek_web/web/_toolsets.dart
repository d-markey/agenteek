import 'package:agenteek/agenteek.dart';
import 'package:better_future/better_future.dart';
import 'package:dart_mcp/client.dart' as mcp;

import 'config/build_config.dart';
import 'config/agent_config_data.dart';

final deepWikiMcpServer = mcp.Implementation(
  name: 'DeepWiki',
  version: '1.0.0',
);

final context7McpServer = mcp.Implementation(
  name: 'Context7',
  version: '1.0.0',
);

final githubMcpServer = mcp.Implementation(name: 'GitHub', version: '1.0.0');

Future<ToolSet> initializeToolSets(
  AgentConfigData config,
  Secrets secrets,
) async {
  final outcomes = await BetterFuture.settle<ToolSet?>({
    'deepwiki': () => deepWikiMcpServer.setup(
      prefix: 'deepwiki',
      scope: 'DeepWiki information for GitHub repositories',
      url: Uri.parse('https://mcp.deepwiki.com/mcp'),
      toolsAcl: AccessControlList.allowAll,
    ),

    'context7': () => context7McpServer.setup(
      prefix: 'context7',
      scope: 'Context7 Open-Source library documentation',
      url: Uri.parse('https://mcp.context7.com/mcp'),
      toolsAcl: AccessControlList.allowAll,
    ),

    'github': (r) async {
      final gitHubpat = await secrets.get('--gh-pat');
      return gitHubpat.isEmpty
          ? ToolSet.empty
          : githubMcpServer.setup(
              prefix: 'github',
              scope: 'GitHub information for repositories',
              url: Uri.parse('https://api.githubcopilot.com/mcp/'),
              headers: {'Authorization': 'Bearer $gitHubpat'},
              toolsAcl: AccessControlList.allowAll,
            );
    },

    if (BuildConfig.withCustomMcp)
      for (final mcpConf in config.mcpServers)
        if (mcpConf.name.isNotEmpty && mcpConf.url != null)
          mcpConf.id: () async {
            Map<String, String>? authHeader;
            if (mcpConf.hasAuth) {
              final header = mcpConf.authHeader;
              var auth = await secrets.get('--${mcpConf.id}');
              if (auth.isNotEmpty) {
                if (header.toLowerCase() == 'authorization') {
                  auth = 'Bearer $auth';
                }
                authHeader = {header: auth};
              }
            }
            return mcp.Implementation(
              name: mcpConf.name,
              version: '1.0.0',
            ).setup(
              prefix: mcpConf.id,
              scope: 'Tools for ${mcpConf.name}',
              url: mcpConf.url!,
              headers: authHeader,
              toolsAcl: AccessControlList.allowAll,
            );
          },
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
