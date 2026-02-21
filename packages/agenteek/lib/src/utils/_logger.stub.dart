class LogSink implements Sink<String> {
  LogSink(this.name);

  final String name;

  void enable() => throw UnimplementedError();
  void disable() => throw UnimplementedError();

  @override
  void add(String message) => throw UnimplementedError();

  @override
  void close() => throw UnimplementedError();
}

class ErrorSink extends LogSink {
  ErrorSink(super.name);
}

void trace(Object message) => throw UnimplementedError();
