import 'dart:io';

import 'package:agenteek/agenteek.dart';

class ConsoleSink implements OutputSink {
  ConsoleSink(this.header);

  final String header;

  // console intput / output
  @override
  void add(String message) {
    for (var line in message.split('\n')) {
      stdout.writeln('$header: $line');
    }
  }

  @override
  void writeln(String message) => add(message);

  @override
  void close() {}
}
