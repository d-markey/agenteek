import 'dart:convert';
import 'package:agenteek/agenteek.dart';
import '../ticket.dart';
import '../tickets_toolset.dart';

/// A tool that creates and opens a new ticket.
Tool openTicketTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.open',
  description: toolset.scoped('Create and open a new ticket'),
  inputSchema: z.object(
    {
      'title': z.string('Ticket title'),
      'description': z.string('Ticket details'),
    },
    required: ['title', 'description'],
  ),
  onCall: (args) => _openTicket(toolset, args),
);

Future<ToolOutcome<String>> _openTicket(TicketToolSet toolset, Json args) async {
  final title = args.getString('title');
  final description = args.getString('description');
  final id = await toolset.getNextTicketId();
  final ticket = Ticket(id, toolset.owner, title, description);
  toolset.tickets[id] = ticket;
  toolset.logger.append('===\n$ticket');
  final fs = toolset.fileSystem;
  if (fs != null) {
    final fname = toolset.getTicketFileName(id);
    await fs.write(fname, jsonEncode(ticket));
  }
  return ToolSuccess('Ticket created successfully with id "$id".');
}
