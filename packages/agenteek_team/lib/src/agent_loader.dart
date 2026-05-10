import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_dart_toolset/dart_toolset.dart';
import 'package:agenteek_files_toolset/files_toolset.dart';
import 'package:agenteek_memory_toolset/memory_toolset.dart';
import 'package:agenteek_tickets_toolset/tickets_toolset.dart';
import 'package:better_future/better_future.dart';
import 'package:dart_mcp/client.dart';
import 'package:yaml/yaml.dart';

import 'agent_conf.dart';

Future<List<AgentConf>> loadAgentsConf(File yaml, Secrets secrets) async {
  final yamlDoc = await yaml.readAsString();
  final yamlConf = (loadYamlDocument(yamlDoc).contents.value as Map)
      .cast<String, Map>();

  String rootAgentName = '';
  final agentsConf = <AgentConf>[];

  for (var e in yamlConf.entries) {
    final agentConf = await AgentConf.fromYamlNode(yaml, e, secrets);

    if (agentsConf.any(($) => $.displayName == agentConf.displayName)) {
      throw StateError(
        'Team member name "${agentConf.displayName}" already exists.',
      );
    }

    if (agentConf.instructor.isEmpty) {
      if (rootAgentName.isNotEmpty) {
        throw StateError(
          'Missing instructor for "${agentConf.displayName}"; the root agent is already defined as "$rootAgentName".',
        );
      }
      rootAgentName = agentConf.displayName;
    }

    for (var entry in agentConf.roots.entries) {
      final path = entry.value['path']?.toString().trim() ?? '';
      if (path.isEmpty) {
        throw StateError('Missing path for root "${entry.key}"');
      }
      final dir = Directory(path);
      if (!await dir.exists()) {
        throw StateError('Directory not found: "${dir.path}"');
      }

      final description = entry.value['description']?.toString().trim() ?? '';
      final readOnly = (entry.value['read-only'] as bool?) ?? true;
      agentConf.registerToolSet(
        FileToolSet(
          prefix: entry.key.toLowerCase(),
          scope: 'file system for $description',
          root: dir.path,
          allowCreate: !readOnly,
          allowReplace: !readOnly,
          allowDelete: !readOnly,
        ),
      );
    }

    for (var tool in agentConf.tools.entries) {
      switch (tool.key) {
        case String $ when $ == 'dart' || $.startsWith('dart_'):
          final path = tool.value['path']?.toString().trim() ?? '';
          if (path.isEmpty) {
            throw StateError('Missing path for dart tool');
          }
          final description =
              tool.value['description']?.toString().trim() ?? '';
          agentConf.registerToolSet(
            DartToolSet(
              prefix: tool.key,
              root: path,
              scope: 'Dart tools for $description',
            ),
          );
        case 'tickets':
          agentConf.registerToolSet(
            TicketToolSet(
              prefix: tool.key,
              owner: '${agentConf.role}-${agentConf.displayName}',
            ),
          );
        case 'memory':
          agentConf.registerToolSet(
            MemoryToolSet(
              prefix: tool.key,
              owner: '${agentConf.role}-${agentConf.displayName}',
            ),
          );
        default:
          print('Unsupported tool "$tool", it will be ignored.');
      }
    }

    if (agentConf.mcp.isNotEmpty) {
      final mcpInitializations = <String, Future<void> Function()>{};

      for (var mcp in agentConf.mcp.entries) {
        switch (mcp.key) {
          case 'github':
            mcpInitializations[mcp.key] = () async {
              final token = await secrets.get('github-pat');
              if (token.isEmpty) {
                throw Exception('Missing Github access token.');
              }
              final toolset =
                  await Implementation(name: 'Github', version: '1.0.0').setup(
                    prefix: 'github',
                    scope: 'Github repositories',
                    url: Uri.parse('https://api.githubcopilot.com/mcp/'),
                    headers: {'Authorization': 'Bearer $token'},
                    toolsAcl: mcp.value,
                  );
              if (toolset != null) {
                agentConf.registerToolSet(toolset);
              }
            };

          default:
            print('Unsupported MCP tool: "${mcp.key}", it will be ignored.');
        }
      }

      final outcomes = await BetterFuture.settle(mcpInitializations);
      for (var entry in outcomes.errors) {
        print('Failed to load MCP tool "${entry.key}": ${entry.value}');
      }
    }

    agentsConf.insert(0, agentConf);
  }

  // make root agent **LAST** in list
  final rootAgent = agentsConf
      .where((a) => a.displayName == rootAgentName)
      .single;
  agentsConf.remove(rootAgent);
  agentsConf.add(rootAgent);

  // return configurations
  return agentsConf;
}
