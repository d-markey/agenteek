class NullSink implements Sink<String> {
  const NullSink();

  @override
  void add(String data) {}

  @override
  void close() {}
}
