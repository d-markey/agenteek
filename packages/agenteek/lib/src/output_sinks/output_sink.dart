class OutputSink implements Sink<String> {
  OutputSink(this._sink);

  final Sink<String> _sink;

  @override
  void add(String data) => _sink.add(data);

  void writeln(String data) => add('$data\n');

  @override
  void close() => _sink.close();
}

class NullOutputSink implements OutputSink {
  const NullOutputSink();

  @override
  Sink<String> get _sink => throw UnimplementedError();

  @override
  void add(String data) {}

  @override
  void writeln(String data) {}

  @override
  void close() {}
}
