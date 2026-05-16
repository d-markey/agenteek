import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import '../ticket.dart';
import '../tickets_toolset.dart';
import '_json_arguments.dart';

/// A tool that updates an existing ticket.
Tool<String> commentOnTicketTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.add_comment',
  description: toolset.scoped('Comment on an existing ticket.'),
  inputSchema: CommentOnTicketArgs.schema,
  onCall: (args) => _commentOnTicket(toolset, CommentOnTicketArgs(args)),
);

Future<ToolSuccess<String>> _commentOnTicket(
  TicketToolSet toolset,
  CommentOnTicketArgs args,
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
    ticket.addComment(author: toolset.owner, message: args.comment);
    toolset.logger.fine('Added comment: $ticket');
    if (fs != null) {
      await fs.write(fname, jsonEncode(ticket));
    }
    return ToolSuccess.ok;
  }
}
