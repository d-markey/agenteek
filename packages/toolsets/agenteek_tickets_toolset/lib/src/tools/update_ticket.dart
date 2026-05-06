import 'dart:convert';
import 'package:agenteek/agenteek.dart';
import '../ticket.dart';
import '../tickets_toolset.dart';

/// A tool that updates an existing ticket.
Tool updateTicketTool(TicketToolSet toolset) => Tool(
  name: '${toolset.prefix}.update',
  description: toolset.scoped(
    'Update an existing ticket; the original ticket is replaced with the provided information.',
  ),
  inputSchema: _inputSchema,
  onCall: (args) => _updateTicket(toolset, args),
);

Future<ToolSuccess<String>> _updateTicket(
  TicketToolSet toolset,
  Json args,
) async {
  final id = args.getInt('ticket_id');
  final title = args.getString('title');
  final description = args.getString('description');
  var ticket = toolset.tickets[id];
  final fs = toolset.fileSystem;
  final fname = toolset.getTicketFileName(id);
  if (ticket == null && fs != null && await fs.exists(fname)) {
    ticket = Ticket.fromJson(jsonDecode(await fs.read(fname)) as Map);
  }
  if (ticket == null) {
    throw 'Ticket "$id" not found.';
  } else {
    ticket.update(toolset.owner, title, description);
    toolset.logger.append('===\n$ticket');
    if (fs != null) {
      await fs.write(fname, jsonEncode(ticket));
    }
    return ToolSuccess.ok;
  }
}

final _inputSchema = Z.object(
  properties: {
    'ticket_id': Z.integer(description: 'Ticket ID'),
    'title': Z.string(description: 'Ticket title'),
    'description': Z.string(description: 'Ticket details'),
  },
  required: ['ticket_id', 'title', 'description'],
);
