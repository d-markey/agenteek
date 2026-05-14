import 'package:agenteek/agenteek.dart';

import '../team_toolset.dart';

/// Lists tesm members.
Tool<String> listMembersTool(TeamToolSet teamToolSet) => Tool(
  name: 'team.list_members',
  description: 'Lists the team members.',
  onCall: (_) => _listMembers(teamToolSet),
);

ToolSuccess<String> _listMembers(TeamToolSet teamToolSet) => ToolSuccess(
  'Team members:\n'
  '${teamToolSet.members.keys.map((k) => '* $k\n').join()}',
);
