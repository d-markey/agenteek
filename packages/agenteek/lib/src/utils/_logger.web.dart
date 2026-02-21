import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '_logger.stub.dart' as base_;

class LogSink extends base_.LogSink {
  LogSink(super.name);

  bool _enabled = false;

  @override
  void enable() => _enabled = true;

  @override
  void disable() => _enabled = false;

  @override
  void add(String message) {
    if (_enabled) {
      _log(message.split('\n').map((l) => '[$name] $l').join('\n'));
    }
  }

  @override
  void close() => disable();
}

class ErrorSink extends LogSink {
  ErrorSink(String name) : super('ERROR/$name');
}

void trace(Object message) =>
    _log(message.toString().split('\n').map((l) => '[TRACE] $l').join('\n'));

void _log(String message) => web.console.log('\n$message'.toJS);
