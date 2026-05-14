import 'package:agenteek/agenteek.dart';
import 'package:meta/meta.dart';

import '_team_member.dart';
import 'tools/clear_history.dart';
import 'tools/list_members.dart';
import 'tools/send_message.dart';

/// A `ToolSet` that provides tools for interacting with a team of AI agent.
class TeamToolSet extends ToolSet {
  /// Initializes a new instance of the `TeamToolSet`.
  ///
  /// This constructor sets up the toolset, registering tools for listing team members,
  /// sending prompts and managing conversation history.
  TeamToolSet() {
    register(listMembersTool(this));
    register(sendMessageTool(this));
    register(clearHistoryTool(this));
  }

  /// The `Agent` instance this toolset wraps.
  final _members = <String, TeamMember>{};

  /// Registers a new team member with this toolset.
  void registerTeamMember(
    Agent agent, {
    OutputSink? agentSink,
    OutputSink? instructorSink,
  }) {
    _members[agent.role] = TeamMember(
      agent,
      agentSink: agentSink,
      instructorSink: instructorSink,
    );
  }
}

@internal
extension TeamToolSetUtils on TeamToolSet {
  Map<String, TeamMember> get members => _members;
}
