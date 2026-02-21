import 'dart:async';

import '_logger.stub.dart'
    if (dart.library.io) '_logger.io.dart'
    if (dart.library.js_interop) '_logger.web.dart'
    as impl_;

typedef LogSink = impl_.LogSink;
typedef ErrorSink = impl_.ErrorSink;

class Log {
  static bool _enabled = false;
  static bool get enabled => _enabled;
  static final _logs = <Log>[];

  static void _enable(Log log) => log._sink.enable();
  static void _disable(Log log) => log._sink.disable();

  static void enable() {
    _enabled = true;
    _logs.forEach(_enable);
  }

  static void disable() {
    _enabled = false;
    _logs.forEach(_disable);
  }

  Log.toSink(LogSink sink) : _sink = sink {
    _logs.add(this);
    if (_enabled) {
      _sink.enable();
    } else {
      _sink.disable();
    }
  }

  Log(String name) : this.toSink(LogSink(name));

  final LogSink _sink;

  String get name => _sink.name;

  void append(Object message) {
    var msg = message;
    if (msg is Function) {
      try {
        // compute message
        msg = msg.call();
      } catch (ex, _) {
        // log error
        msg = 'failed\n$ex';
      }
    }

    if (msg is Future) {
      // async
      final future = msg;
      final id = future.hashCode.toRadixString(16).padLeft(8, '0');
      append('[$id] *** registering ${future.runtimeType}...');
      unawaited(
        future.then(
          (res) => append('[$id] *** completed\n$res\n[$id] *** done'),
          onError: (ex) => append('[$id] *** failed\n$ex\n[$id] *** done'),
        ),
      );
    } else {
      // sync
      final ts = '[${DateTime.now().toIso8601String()}]';
      _sink.add(msg.toString().split('\n').map((l) => '$ts $l').join('\n'));
    }
  }
}

final chatLogger = Log('chat');
final modelLogger = Log('model');
