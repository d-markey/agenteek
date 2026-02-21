import 'dart:io';

class AgentSink implements Sink<String> {
  AgentSink(this.header);

  final String header;

  // console intput / output
  @override
  void add(String message) {
    for (var line in message.split('\n')) {
      stdout.writeln('$header: $line');
    }
  }

  @override
  void close() {}
}
