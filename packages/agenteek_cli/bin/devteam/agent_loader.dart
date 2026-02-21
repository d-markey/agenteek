import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_dart/agenteek_dart.dart';
import 'package:agenteek_files/agenteek_files.dart';
import 'package:agenteek_memory/agenteek_memory.dart';
import 'package:agenteek_tickets/agenteek_tickets.dart';
import 'package:dart_mcp/client.dart';
import 'package:yaml/yaml.dart';

import 'agent_conf.dart';

Future<List<AgentConf>> loadAgentsConf(String yaml, Secrets secrets) async {
  final yamlConf = (loadYamlDocument(yaml).contents.value as Map)
      .cast<String, Map>();

  String rootAgentName = '';
  final agentsConf = <AgentConf>[];

  for (var e in yamlConf.entries) {
    final agentConf = AgentConf.fromYamlNode(e);

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
      final path = entry.value['path']?.trim() ?? '';
      if (path.isEmpty) {
        throw StateError('Missing path for root "${entry.key}"');
      }
      final displayPath = entry.value['display-path']?.trim() ?? '';
      final dir = Directory(path);
      if (!await dir.exists()) {
        throw StateError('Directory not found: "${dir.path}"');
      }

      agentConf.registerToolSet(
        FileToolSet(
          prefix: entry.key.toLowerCase(),
          scope: 'root file system for `${entry.key}`',
          root: dir.path,
          displayRoot: displayPath,
          allowCreate: false,
          allowReplace: false,
        ),
      );
    }

    for (var tool in agentConf.tools) {
      switch (tool) {
        case 'dart':
          agentConf.registerToolSet(DartToolSet(prefix: 'dart'));
        case 'tickets':
          agentConf.registerToolSet(
            TicketToolSet(
              prefix: 'tickets',
              owner: '${agentConf.role}-${agentConf.displayName}',
            ),
          );
        case 'memory':
          agentConf.registerToolSet(
            MemoryToolSet(
              prefix: 'memory',
              owner: '${agentConf.role}-${agentConf.displayName}',
            ),
          );
        default:
          modelLogger.append('Unsupported tool "$tool", it will be ignored.');
      }
    }

    if (agentConf.mcp.isNotEmpty) {
      final mcpInitializations = <Future<McpToolSet?>>[];

      for (var mcp in agentConf.mcp.entries) {
        switch (mcp.key) {
          case 'github':
            final token = await secrets.get('github-pat');
            if (token.isEmpty) throw Exception('Missing Github access token.');
            mcpInitializations.add(
              Implementation(name: 'Github', version: '1.0.0').setup(
                prefix: 'github',
                scope: 'Github repositories',
                url: Uri.parse('https://api.githubcopilot.com/mcp/'),
                headers: {'Authorization': 'Bearer $token'},
                toolsAcl: mcp.value,
              ),
            );
          case 'imaging':
            final apiKey = await secrets.get('imaging-api-key');
            if (apiKey.isEmpty) throw Exception('Missing Imaging API key.');
            mcpInitializations.add(
              Implementation(name: 'CAST Imaging', version: '1.0.0').setup(
                prefix: 'imaging',
                scope: 'CAST Imaging',
                url: Uri.parse('https://demo-imaging-v3.castsoftware.com/mcp'),
                headers: {'x-api-key': apiKey},
                toolsAcl: mcp.value,
              ),
            );
          default:
            modelLogger.append(
              'Unsupported MCP tool: "${mcp.key}", it will be ignored.',
            );
        }
      }

      final mcpToolsets = await Future.wait(mcpInitializations);
      mcpToolsets.nonNulls.forEach(agentConf.registerToolSet);
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
