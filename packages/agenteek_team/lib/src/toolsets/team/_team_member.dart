import 'package:agenteek/agenteek.dart';

class TeamMember {
  TeamMember(this.agent, {this.agentSink, this.instructorSink});

  final Agent agent;
  final OutputSink? agentSink;
  final OutputSink? instructorSink;
}
