import 'package:agenteek/agenteek.dart';

extension type DeleteFileArgs(Json _json) {
  String get path {
    final path = _json.getString('path').trim();
    return path.startsWith('/') ? path.substring(1) : path;
  }

  static final schema = Z.object(
    properties: {'path': Z.string(description: 'Path of the file to delete')},
    required: ['path'],
  );
}

extension type CreateFileArgs(Json _json) {
  String get path {
    final path = _json.getString('path').trim();
    return path.startsWith('/') ? path.substring(1) : path;
  }

  String get text => _json.getString('text', defaultValue: '');

  static final schema = Z.object(
    properties: {
      'path': Z.string(description: 'File path'),
      'text': Z.string(description: 'Text to write to the file'.optional('')),
    },
    required: ['path'],
  );
}
