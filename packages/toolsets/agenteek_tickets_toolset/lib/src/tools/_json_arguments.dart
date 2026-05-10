import 'package:agenteek/agenteek.dart';

extension type OpenTicketArgs(Json _json) {
  String get title => _json.getString('title');
  String get description => _json.getString('description');

  static final schema = S.object(
    properties: {
      'title': S.string(description: 'Ticket title'),
      'description': S.string(description: 'Ticket details'),
    },
    required: ['title', 'description'],
  );
}

extension type ReadTicketArgs(Json _json) {
  int get ticketId => _json.getInt('ticket_id');

  static final schema = S.object(
    properties: {'ticket_id': S.integer(description: 'Ticket ID')},
    required: ['ticket_id'],
  );
}

extension type UpdateTicketArgs(Json _json) {
  int get ticketId => _json.getInt('ticket_id');
  String get title => _json.getString('title');
  String get description => _json.getString('description');

  static final schema = S.object(
    properties: {
      'ticket_id': S.integer(description: 'Ticket ID'),
      'title': S.string(description: 'Ticket title'),
      'description': S.string(description: 'Ticket details'),
    },
    required: ['ticket_id', 'title', 'description'],
  );
}
