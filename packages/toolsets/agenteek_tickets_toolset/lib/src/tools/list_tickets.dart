import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import '../ticket.dart';
import '../tickets_toolset.dart';

/// A tool that lists all tickets.
Tool<List<Json>> listTicketsTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.list',
  description: toolset.scoped('List all tickets'),
  onCall: (_) => _listTickets(toolset),
);

Future<ToolSuccess<List<Json>>> _listTickets(TicketToolSet toolset) async {
  if (toolset.fileSystem != null) {
    final fs = toolset.fileSystem!;
    await for (var f in toolset.listTicketFiles(fs)) {
      final match = toolset.pattern.firstMatch(f);
      if (match != null) {
        final id = int.parse(match.group(1)!);
        if (!toolset.tickets.containsKey(id)) {
          final ticket = Ticket.fromJson(jsonDecode(await fs.read(f)));
          if (ticket != null) toolset.tickets[id] = ticket;
        }
      }
    }
  }
  return ToolSuccess(
    toolset.tickets.values
        .map((t) => {'ticket_id': t.id, 'title': t.title})
        .toList(),
  );
}
