import 'dart:async';

import 'package:agenteek/agenteek_dbg.dart' as dbg show trace;
import 'package:stream_channel/stream_channel.dart';

import '_helpers.dart';
import 'http_client.dart';

class HttpChannel
    with StreamChannelMixin<String>
    implements StreamChannel<String> {
  HttpChannel({required Uri url, Map<String, String>? headers})
    : _url = url,
      _headers = headers {
    final sub = _input.stream.listen(_process);
    _output.onCancel = sub.cancel;
  }

  Uri _url;
  final Map<String, String>? _headers;

  final _input = StreamController<String>();
  final _output = StreamController<String>();

  @override
  StreamSink<String> get sink => _input;

  @override
  Stream<String> get stream => _output.stream;

  late final _client = DbgClient(
    withCredentials:
        _headers?.keys.any((k) => k.toLowerCase() == 'authorization') ?? false,
    // traceRequests: true,
    // traceResponses: true,
  );
  String? _sessionId;

  Completer<void> _pendingOperation = Completer()..complete();

  void _process(String data) async {
    // avoid concurrent messages in HTTP channel
    if (!_pendingOperation.isCompleted) {
      dbg.trace('AWAITING PENDING OPERATION...');
      await _pendingOperation.future;
    }
    _pendingOperation = Completer();

    // prepare headers
    final headers = {
      'Accept': 'application/json,text/event-stream',
      'Content-Type': 'application/json',
      'User-Agent': 'agenteek',
      'Mcp-Session-Id': ?_sessionId,
      if (_headers != null) ..._headers,
    };

    try {
      while (true) {
        final res = await _client.post(_url, headers: headers, body: data);

        if (res.statusCode >= 200 && res.statusCode < 300) {
          // OK
          _sessionId ??= res.headers['mcp-session-id'];
          return _reply(res);
        }

        if (res.statusCode == 307 /*HttpStatus.temporaryRedirect*/ ||
            res.statusCode == 308 /*HttpStatus.permanentRedirect*/ ||
            res.statusCode == 301 /*HttpStatus.movedTemporarily*/ ||
            res.statusCode == 302 /*HttpStatus.found*/ ) {
          _url = Uri.parse(res.headers['location']!.trim());
          continue;
        } else if (res.statusCode == 429 /*HttpStatus.tooManyRequests*/ ) {
          await _retry(res);
          continue;
        }

        // fail
        throw _httpError(res);
      }
    } catch (ex, st) {
      _output.addError(ex, st);
    } finally {
      _pendingOperation.complete();
    }
  }

  void _reply(Response res) {
    if (res.body.isEmpty) return;

    final contentType = res.headers['content-type']?.toLowerCase() ?? '';

    if (contentType == 'application/json') {
      _output.add(res.body);
      return;
    } else if (contentType == 'text/event-stream') {
      for (var message in _eventStream(res.body)) {
        if (message['event'] == 'message' && message.containsKey('data')) {
          _output.add(message['data']!);
        }
      }
    }
  }

  Iterable<Map<String, String>> _eventStream(String payload) sync* {
    payload = payload.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final events = payload.split('\n\n');
    for (var event in events) {
      final message = <String, String>{};
      final lines = event.split('\n');
      for (var line in lines) {
        final colonIdx = line.indexOf(':');
        if (colonIdx < 0) {
          // treat as field name with empty value
          final key = line.trim();
          if (key.isNotEmpty) {
            message[key] = '';
          }
        } else if (colonIdx == 0) {
          // comment
        } else {
          // key/value pair: concatenate values for same key
          final key = line.substring(0, colonIdx).trim();
          final value = line.substring(colonIdx + 1).trimLeft();
          message.update(key, (v) => '$v\n$value', ifAbsent: () => value);
        }
      }
      if (message.isNotEmpty) {
        yield message;
      }
    }
  }

  Future<void> _retry(Response res) {
    final retryAfter = res.headers['retry-after'] ?? '';
    final duration = retryAfter.isEmpty
        ? const Duration(seconds: 1)
        : parseRetryAfter(retryAfter);
    return (duration == null)
        ? Future.error(
            _httpError(res, 'Invalid "retry-after" value: "$retryAfter"'),
          )
        : Future.delayed(duration);
  }
}

Exception _httpError(BaseResponse res, [String? details]) => Exception(
  details == null
      ? 'HTTP Exception ${res.statusCode} - ${res.reasonPhrase}'
      : 'HTTP Exception ${res.statusCode} - ${res.reasonPhrase} - $details',
);
