import 'output_sink.dart';

abstract interface class StreamingOutputSink implements OutputSink {
  Future<void> start();
  Future<void> finish();

  @override
  void writeln(String data) => add('$data\n');
}

class NullStreamingOutputSink implements StreamingOutputSink {
  const NullStreamingOutputSink();

  static final _completed = Future<void>.value();

  @override
  Future<void> start() => _completed;

  @override
  Future<void> finish() => _completed;

  @override
  void add(String data) {}

  @override
  void writeln(String data) {}

  @override
  void close() {}
}
