import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '_logger.stub.dart' as base_;
import 'debug.dart' as dbg;

Directory? _logDir;

Future<RandomAccessFile> _openWriter(String name) {
  var logDir = _logDir;
  if (logDir == null) {
    String $nn(int n) => n.toString().padLeft(2, '0');
    String $nnnn(int n) => n.toString().padLeft(4, '0');
    String $nnnnnn(int n) => n.toString().padLeft(6, '0');
    final now = DateTime.now();
    final timestamp =
        '${$nnnn(now.year)}${$nn(now.month)}${$nn(now.day)}'
        '.${$nn(now.hour)}${$nn(now.minute)}${$nn(now.second)}'
        '.${$nnnnnn(now.millisecond * 1000 + now.microsecond)}';
    logDir = Directory.systemTemp.createTempSync('agenteek_logs');
    logDir.delete();
    var path = logDir.absolute.path;
    final idx = path.indexOf('agenteek_logs');
    path = path.substring(0, idx + 'agenteek_logs'.length);
    logDir = Directory(p.join(path, timestamp))..createSync(recursive: true);
    _logDir = logDir;
    dbg.trace('Logging to $logDir');
  }
  return File(
    p.join(logDir.path, 'agenteek_$name.log'),
  ).open(mode: FileMode.append);
}

class LogSink extends base_.LogSink {
  LogSink(super.name);

  RandomAccessFile? _output;
  Completer<RandomAccessFile>? _outputCompleter;

  @override
  void enable() {
    if (_output != null) return;
    if (_outputCompleter != null) return;
    final completer = _outputCompleter = Completer();
    completer.future.then((o) => _output = o);
    _openWriter(name).then(completer.complete);
  }

  @override
  void disable() {
    if (_output != null) {
      _output!.flushSync();
    } else if (_outputCompleter != null) {
      _outputCompleter!.future.then((o) => o.flushSync());
    }
    _output = null;
    _outputCompleter = null;
  }

  @override
  void add(String message) {
    if (_output != null) {
      _output!.writeStringSync('\n$message\n');
    } else if (_outputCompleter != null) {
      _outputCompleter!.future.then((o) => o.writeStringSync('\n$message\n'));
    }
  }

  @override
  void close() {
    if (_output != null) {
      _output!.flushSync();
      _output!.close();
    } else if (_outputCompleter != null) {
      _outputCompleter!.future.then((o) {
        o.flushSync();
        o.close();
      });
    }
    _output = null;
    _outputCompleter = null;
  }
}

class ErrorSink extends base_.ErrorSink {
  ErrorSink(super.name);

  bool _enabled = true;

  @override
  void enable() {
    _enabled = true;
  }

  @override
  void disable() {
    _enabled = false;
  }

  @override
  void add(String message) {
    if (_enabled) {
      stderr.writeln(
        message.split('\n').map((l) => '[ERROR/$name] $l').join('\n'),
      );
    }
  }

  @override
  void close() {
    stderr.flush();
  }
}

void trace(Object message) => stderr.writeln(
  '\n${message.toString().split('\n').map((l) => '[TRACE] $l').join('\n')}',
);
