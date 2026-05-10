import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import '../ticket.dart';
import '../tickets_toolset.dart';
import '_json_arguments.dart';

/// A tool that updates an existing ticket.
Tool updateTicketTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.update',
  description: toolset.scoped(
    'Update an existing ticket; the original ticket is replaced with the provided information.',
  ),
  inputSchema: UpdateTicketArgs.schema,
  onCall: (args) => _updateTicket(toolset, UpdateTicketArgs(args)),
);

Future<ToolSuccess<String>> _updateTicket(
  TicketToolSet toolset,
  UpdateTicketArgs args,
) async {
  var ticket = toolset.tickets[args.ticketId];
  final fs = toolset.fileSystem;
  final fname = toolset.getTicketFileName(args.ticketId);
  if (ticket == null && fs != null && await fs.exists(fname)) {
    ticket = Ticket.fromJson(jsonDecode(await fs.read(fname)) as Map);
  }
  if (ticket == null) {
    throw 'Ticket "${args.ticketId}" not found.';
  } else {
    ticket.update(toolset.owner, args.title, args.description);
    toolset.logger.append('===\n$ticket');
    if (fs != null) {
      await fs.write(fname, jsonEncode(ticket));
    }
    return ToolSuccess.ok;
  }
}
