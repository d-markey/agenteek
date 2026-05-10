import 'package:agenteek/agenteek.dart';

extension type Ticket._(Map<String, Object> _json) implements Object {
  factory Ticket(int id, String createdBy, String title, String description) =>
      Ticket._({
        'ticket_id': id,
        'title': title,
        'description': description,
        'created-by': createdBy,
        'created-on': DateTime.now().toUtc().toIso8601String(),
      });

  static Ticket? fromJson(Map json) =>
      (json.keys.every((k) => k is String) &&
          json.values.every((v) => v != null) &&
          json.containsKey('ticket_id') &&
          json.containsKey('title'))
      ? Ticket._(json.cast<String, Object>())
      : null;

  String get createdBy => _json['created-by'] as String;
  DateTime get createdOn => DateTime.parse(_json['created-on'] as String);

  String get modifiedBy => _json['modified-by'] as String? ?? createdBy;
  DateTime get modifiedOn => DateTime.parse(
    _json['modified-on'] as String? ?? _json['created-on'] as String,
  );

  int get id => _json['ticket_id'] as int;
  String get title => _json['title'] as String;
  String get description => _json['description'] as String;

  void update(String modifiedBy, String title, String description) {
    _json['modified-by'] = modifiedBy;
    _json['modified-on'] = DateTime.now().toUtc().toIso8601String();
    _json['title'] = title;
    _json['description'] = description;
  }

  Json toJson() => _json;
}
