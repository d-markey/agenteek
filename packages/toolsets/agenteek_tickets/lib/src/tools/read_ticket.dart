import 'dart:convert';
import 'package:agenteek/agenteek.dart';
import '../ticket.dart';
import '../tickets_toolset.dart';

/// A tool that reads an existing ticket.
Tool readTicketTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.read',
  description: toolset.scoped('Read an existing ticket.'),
  inputSchema: z.object(
    {'ticket_id': z.int('Ticket ID')},
    required: ['ticket_id'],
  ),
  onCall: (args) => _readTicket(toolset, args),
);

Future<ToolOutcome<Ticket>> _readTicket(TicketToolSet toolset, Json args) async {
  final id = args.getInt('ticket_id');
  var ticket = toolset.tickets[id];
  if (ticket == null) {
    final fs = toolset.fileSystem;
    final fname = toolset.getTicketFileName(id);
    if (fs != null && await fs.exists(fname)) {
      ticket = Ticket.fromJson(jsonDecode(await fs.read(fname)) as Map);
    }
  }
  if (ticket == null) throw 'Ticket "$id" not found.';
  return ToolSuccess(ticket);
}
