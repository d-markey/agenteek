import 'package:agenteek/agenteek.dart';

extension type Ticket._(Json _json) implements Object {
  factory Ticket({
    required int id,
    required String createdBy,
    required String title,
    required String description,
  }) => Ticket._({
    'ticket_id': id,
    'status': 'open',
    'title': title,
    'description': description,
    'created-by': createdBy,
    'created-on': DateTime.now().toUtc().toIso8601String(),
  });

  static Ticket? fromJson(Map json) =>
      (json is Map<String, dynamic> || json.keys.every((k) => k is String)) &&
          json.containsKey('created-by') &&
          json.containsKey('ticket_id') &&
          json.containsKey('title') &&
          json.containsKey('status')
      ? Ticket._(json.cast<String, Object?>())
      : null;

  String? get createdBy => _json['created-by'] as String?;

  DateTime? get createdOn => (_json['created-on'] as String?)?._toDate();

  String? get modifiedBy => _json['modified-by'] as String? ?? createdBy;

  DateTime? get modifiedOn =>
      (_json['modified-on'] as String?)?._toDate() ?? createdOn;

  int get id => _json['ticket_id'] as int;

  String get status => _json['status'] as String;

  String get title => _json['title'] as String;

  String get description => _json['description'] as String;

  Iterable<Comment> get comments =>
      (_json['comments'] as List? ?? const []).cast<Comment>();

  void update({
    required String modifiedBy,
    String? title,
    String? description,
    String? status,
  }) {
    _json['modified-by'] = modifiedBy;
    _json['modified-on'] = DateTime.now().toUtc().toIso8601String();
    if (title != null) _json['title'] = title;
    if (description != null) _json['description'] = description;
    if (status != null) _json['status'] = status;
  }

  void addComment({required String author, required String message}) {
    var comments = (_json['comments'] as List?)?.cast<Comment>();
    if (comments == null) {
      comments = <Comment>[];
      _json['comments'] = comments;
    }
    final comment = Comment(author: author, message: message);
    comments.add(comment);
    _json['modified-by'] = author;
    _json['modified-on'] = comment._json['date-time'];
  }

  Json toJson() => _json;
}

extension type Comment._(Json _json) implements Object {
  factory Comment({required String author, required String message}) =>
      Comment._({
        'author': author,
        'message': message,
        'date-time': DateTime.now().toUtc().toIso8601String(),
      });

  String get author => _json['author'] as String;

  String get message => _json['message'] as String;

  DateTime get dateTime => (_json['date-time'] as String)._toDate()!;
}

extension on String {
  DateTime? _toDate() => trim().isEmpty ? null : DateTime.parse(this);
}
