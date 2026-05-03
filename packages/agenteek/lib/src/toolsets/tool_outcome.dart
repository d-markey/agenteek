import 'dart:convert';

sealed class ToolOutcome<T> {
  const ToolOutcome();

  T get result;

  dynamic toJson();
}

class ToolSuccess<T> extends ToolOutcome<T> {
  const ToolSuccess(this.result);

  @override
  final T result;

  @override
  dynamic toJson() => (result is String?) ? (result ?? '') : jsonEncode(result);

  static const ok = ToolSuccess<String>('OK');
}

class ToolError<T> extends ToolOutcome<T> {
  const ToolError(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;

  @override
  T get result => switch (stackTrace) {
    StackTrace st => Error.throwWithStackTrace(error, st),
    _ => throw error,
  };

  @override
  dynamic toJson() => (result is Map<String, dynamic>)
      ? jsonEncode(result)
      : (result?.toString() ?? '');
}
