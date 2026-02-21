import 'dart:convert';

import 'package:agenteek/agenteek.dart';
import 'package:dartantic_interface/dartantic_interface.dart' as ai_;

import 'ticket.dart';

/// A `ToolSet` that provides tools for managing tickets.
class TicketToolSet extends ToolSet {
  TicketToolSet({
    required this.prefix,
    required this.owner,
    String? scope,
    this.fileSystem,
  }) : scope = scope?.trim() ?? '',
       _logger = Log('tickets_$owner') {
    // register tools
    register(_listTicketsDeclaration);
    register(_openTicketDeclaration);
    register(_updateTicketDeclaration);
    register(_readTicketDeclaration);
  }

  /// The prefix used as a namespace for ticket-related tools.
  final String prefix;

  /// A description of the scope covered by this toolset.
  final String scope;

  /// The name of the owner of this toolset.
  final String owner;

  /// The root file system for ticket files.
  final FileSystem? fileSystem;

  final _tickets = <int, Ticket>{};

  final Log _logger;

  /// Defines the `ToolSpec` for listing tickets.
  ai_.Tool get _listTicketsDeclaration => ai_.Tool(
    name: '${prefix}_list',
    description: _scoped('List all tickets'),
    onCall: (args) async {
      if (fileSystem != null) {
        final fs = fileSystem!;
        await for (var f in _listTicketFiles(fs)) {
          final id = int.parse(_pattern.firstMatch(f)!.group(1)!);
          if (!_tickets.containsKey(id)) {
            final ticket = Ticket.fromJson(jsonDecode(await fs.read(f)));
            if (ticket != null) _tickets[id] = ticket;
          }
        }
      }
      return {
        'results': _tickets.values
            .map((t) => {'ticket_id': t.id, 'title': t.title})
            .toList(),
      };
    },
  );

  final _pattern = RegExp('ticket_(\\d+)\\.json');

  String _getTicketFileName(int id) => 'ticket_$id.json';

  Stream<String> _listTicketFiles(FileSystem fs) =>
      fs.list().where((f) => _pattern.hasMatch(f));

  Future<int> _getNextTicketId() async {
    var maxId = _tickets.length - 1;
    if (fileSystem != null) {
      await for (var f in _listTicketFiles(fileSystem!)) {
        final id = int.parse(_pattern.firstMatch(f)!.group(1)!);
        if (id > maxId) maxId = id;
      }
    }
    return maxId + 1;
  }

  /// Defines the `ToolSpec` for creating a ticket.
  ai_.Tool get _openTicketDeclaration => ai_.Tool(
    name: '${prefix}_open',
    description: _scoped('Create and open a new ticket'),
    inputSchema: z.object(
      {
        'title': z.string('Ticket title'),
        'description': z.string('Ticket details'),
      },
      required: ['title', 'description'],
    ),
    onCall: (args) async {
      args as Json;
      final title = args['title'] as String;
      final description = args['description'] as String;
      final id = await _getNextTicketId();
      final ticket = Ticket(id, owner, title, description);
      _tickets[id] = ticket;
      _logger.append('===\n$ticket');
      final fs = fileSystem;
      if (fs != null) {
        final fname = _getTicketFileName(id);
        await fs.write(fname, jsonEncode(ticket));
      }
      return {'result': 'Ticket created successfully with id `$id`.'};
    },
  );

  /// Defines the `ToolSpec` for creating a ticket.
  ai_.Tool get _updateTicketDeclaration => ai_.Tool(
    name: '${prefix}_update',
    description: _scoped(
      'Update an existing ticket; the original ticket is replaced with the provided information.',
    ),
    inputSchema: z.object(
      {
        'ticket_id': z.int('Ticket ID'),
        'title': z.string('Ticket title'),
        'description': z.string('Ticket details'),
      },
      required: ['ticket_id', 'title', 'description'],
    ),
    onCall: (args) async {
      args as Json;
      final id = args['ticket_id'] as int;
      final title = args['title'] as String;
      final description = args['description'] as String;
      var ticket = _tickets[id];
      final fs = fileSystem;
      final fname = _getTicketFileName(id);
      if (ticket == null && fs != null && await fs.exists(fname)) {
        ticket = Ticket.fromJson(jsonDecode(await fs.read(fname)) as Map);
      }
      if (ticket == null) {
        return {'error': 'Ticket `$id` not found.'};
      } else {
        ticket.update(owner, title, description);
        _logger.append('===\n$ticket');
        if (fs != null) {
          await fs.write(fname, jsonEncode(ticket));
        }
        return {'result': 'Ticket `$id` updated successfully.'};
      }
    },
  );

  /// Defines the `ToolSpec` for reading a ticket.
  ai_.Tool get _readTicketDeclaration => ai_.Tool(
    name: '${prefix}_read',
    description: _scoped('Read an existing ticket.'),
    inputSchema: z.object(
      {'ticket_id': z.int('Ticket ID')},
      required: ['ticket_id'],
    ),
    onCall: (args) async {
      args as Json;
      final id = args['id'] as int;
      var ticket = _tickets[id];
      if (ticket == null) {
        final fs = fileSystem;
        final fname = _getTicketFileName(id);
        if (fs != null && await fs.exists(fname)) {
          ticket = Ticket.fromJson(jsonDecode(await fs.read(fname)) as Map);
        }
      }
      return (ticket != null)
          ? {'result': ticket}
          : throw Exception('Ticket `$id` not found.');
    },
  );

  /// A helper method to generate a scoped description for tool functions.
  ///
  /// - [description]: The base description of the tool.
  ///
  /// Returns a string with the description, including the root path and
  /// an optional scope.
  String _scoped(String description) =>
      scope.isEmpty ? '$description.' : '$description; **scope: $scope**. ';
}
