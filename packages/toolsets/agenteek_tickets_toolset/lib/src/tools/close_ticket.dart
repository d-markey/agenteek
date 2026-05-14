import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import '../ticket.dart';
import '../tickets_toolset.dart';
import '_json_arguments.dart';

/// A tool that updates an existing ticket.
Tool<String> closeTicketTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.close',
  description: toolset.scoped('Close an existing ticket.'),
  inputSchema: CloseTicketArgs.schema,
  onCall: (args) => _closeTicket(toolset, CloseTicketArgs(args)),
);

Future<ToolSuccess<String>> _closeTicket(
  TicketToolSet toolset,
  CloseTicketArgs args,
) async {
  var ticket = toolset.tickets[args.ticketId];
  final fs = toolset.fileSystem;
  final fname = toolset.getTicketFileName(args.ticketId);
  if (ticket == null && fs != null && await fs.exists(fname)) {
    ticket = Ticket.fromJson(jsonDecode(await fs.read(fname)) as Map);
  }
  if (ticket == null) {
    throw 'Ticket "${args.ticketId}" not found.';
  } else if (ticket.status == 'closed') {
    throw 'Ticket "${args.ticketId}" is already closed. No changes have been applied.';
  } else {
    if (args.comment.isNotEmpty) {
      ticket.addComment(author: toolset.owner, message: args.comment);
    }
    ticket.update(modifiedBy: toolset.owner, status: 'closed');
    toolset.logger.append('===\n$ticket');
    if (fs != null) {
      await fs.write(fname, jsonEncode(ticket));
    }
    return ToolSuccess.ok;
  }
}
