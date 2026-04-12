abstract interface class StreamingStringSink implements Sink<String> {
  Future<void> start();
  Future<void> finish();
}

class NullStreamingStringSink implements StreamingStringSink {
  const NullStreamingStringSink();

  @override
  Future<void> start() => Future<void>.value();

  @override
  Future<void> finish() => Future<void>.value();

  @override
  void add(String data) {}

  @override
  void close() {}
}
