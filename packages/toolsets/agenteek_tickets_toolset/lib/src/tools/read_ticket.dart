import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import '../ticket.dart';
import '../tickets_toolset.dart';
import '_json_arguments.dart';

/// A tool that reads an existing ticket.
Tool<Ticket> readTicketTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.read',
  description: toolset.scoped('Read an existing ticket.'),
  inputSchema: ReadTicketArgs.schema,
  onCall: (args) => _readTicket(toolset, ReadTicketArgs(args)),
);

Future<ToolSuccess<Ticket>> _readTicket(
  TicketToolSet toolset,
  ReadTicketArgs args,
) async {
  var ticket = toolset.tickets[args.ticketId];
  if (ticket == null) {
    final fs = toolset.fileSystem;
    final fname = toolset.getTicketFileName(args.ticketId);
    if (fs != null && await fs.exists(fname)) {
      ticket = Ticket.fromJson(jsonDecode(await fs.read(fname)) as Map);
    }
  }
  if (ticket == null) throw 'Ticket "${args.ticketId}" not found.';
  return ToolSuccess(ticket);
}
