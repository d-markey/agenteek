import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import '../ticket.dart';
import '../tickets_toolset.dart';
import '_json_arguments.dart';

/// A tool that creates and opens a new ticket.
Tool<String> openTicketTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.open',
  description: toolset.scoped('Create and open a new ticket'),
  inputSchema: OpenTicketArgs.schema,
  onCall: (args) => _openTicket(toolset, OpenTicketArgs(args)),
);

Future<ToolSuccess<String>> _openTicket(
  TicketToolSet toolset,
  OpenTicketArgs args,
) async {
  final id = await toolset.getNextTicketId();
  final ticket = Ticket(
    id: id,
    createdBy: toolset.owner,
    title: args.title,
    description: args.description,
  );
  toolset.tickets[id] = ticket;
  toolset.logger.fine('Opened: $ticket');
  final fs = toolset.fileSystem;
  if (fs != null) {
    final fname = toolset.getTicketFileName(id);
    await fs.write(fname, jsonEncode(ticket));
  }
  return ToolSuccess('Ticket created successfully with id "$id".');
}
