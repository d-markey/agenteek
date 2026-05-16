import 'dart:async';

import '../commands/command.dart';
import '../toolsets/toolset_exception.dart';

typedef Json = Map<String, Object?>;

// typedef ToolFunction = FutureOr<dynamic> Function(Json);
// typedef JsonToolFunction = FutureOr<Json> Function(Json);
// typedef StrToolFunction = FutureOr<String> Function(Json);

typedef PromptCallback = FutureOr<String> Function();

typedef NewConversationCallback = FutureOr<void> Function();

typedef UserCommandHandler = Command? Function(String label, List<String> args);

typedef ErrorCallback =
    FutureOr<String?> Function(Object error, [StackTrace? stackTrace]);

extension JsonExtension on Json {
  int getInt(String key, {int? defaultValue}) {
    final value = this[key]?.toString() ?? '';
    if (value.isEmpty) {
      return (defaultValue != null)
          ? defaultValue
          : throw MissingArgumentException(key);
    } else {
      final parsed = int.tryParse(value);
      return (parsed != null)
          ? parsed
          : throw InvalidArgumentException(key, 'int');
    }
  }

  String getString(String key, {String? defaultValue, bool trim = true}) {
    var value = this[key]?.toString() ?? '';
    if (trim) value = value.trim();

    if (value.isEmpty) {
      return (defaultValue != null)
          ? defaultValue
          : throw MissingArgumentException(key);
    } else {
      return value;
    }
  }

  bool getBool(String key, {bool? defaultValue}) {
    final value = this[key]?.toString().toLowerCase() ?? '';
    if (value.isEmpty) {
      return (defaultValue != null)
          ? defaultValue
          : throw MissingArgumentException(key);
    } else if (value == 'true') {
      return true;
    } else if (value == 'false') {
      return false;
    } else {
      throw InvalidArgumentException(key, 'bool');
    }
  }

  List<T> getList<T>(String key, {List<T>? defaultValue}) {
    final value = this[key];
    if (value is List<T>) return value;
    if (value != null && value is! List) {
      throw InvalidArgumentException(key, 'List of $T');
    }

    value as List?;

    if (value == null) {
      return (defaultValue != null)
          ? defaultValue
          : throw MissingArgumentException(key);
    } else {
      try {
        return value.map((e) => e as T).toList();
      } catch (e) {
        throw InvalidArgumentException(key, 'List of $T');
      }
    }
  }
}
