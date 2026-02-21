import 'package:http/http.dart';

import '../utils/debug.dart' as dbg;
import '../utils/types.dart';
import '../utils/unique_id.dart';
import '_client_stub.dart'
    if (dart.library.io) '_client_io.dart'
    if (dart.library.js_interop) '_client_web.dart'
    as impl_;

export 'package:http/http.dart';

class DbgClient with BaseClient implements Client {
  DbgClient({
    this.withCredentials = false,
    this.traceRequests = false,
    this.traceResponses = false,
    this.customErrorHandler,
  }) : _client = impl_.initClient(withCredentials: withCredentials);

  final bool withCredentials;
  final bool traceRequests;
  final bool traceResponses;
  final CustomErrorHandler? customErrorHandler;

  Client? _client;

  static void _traceRequest(String id, BaseRequest req) {
    dbg.trace(
      '****\n'
      '[$id] >>>> request = ${req.method} ${req.url}\n'
      '[$id] Headers:\n'
      '${req.headers.dump((e) => '[$id]   > ${e.key}: ${e.value}')}\n'
      '[$id] Body:\n'
      '[$id] ${(req is Request) ? req.body : '[${req.runtimeType}]'}',
    );
  }

  static Future<StreamedResponse> _traceResponse(
    String id,
    StreamedResponse resp,
  ) async {
    // load response and rebuild the streamed response
    final res = await Response.fromStream(resp);
    resp = resp.rebuild(res.bodyBytes);
    dbg.trace(
      '[$id] <<<< response = ${resp.statusCode} ${resp.reasonPhrase ?? ''} ${resp.request?.method ?? ''} ${resp.request?.url ?? ''}\n'
      '[$id] Headers:\n'
      '${resp.headers.dump((e) => '[$id]   < ${e.key}: ${e.value}')}\n'
      '[$id] Body:\n'
      '[$id] ${res.body}\n'
      '****',
    );
    return resp;
  }

  final _uniqueId = UniqueIdGenerator();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (_client == null) {
      throw StateError('Client has been closed.');
    }

    String? id;
    if (traceRequests) {
      id = _uniqueId.string();
      _traceRequest(id, request);
    }

    var retry = 0;
    StreamedResponse? response;
    while (retry < 5) {
      retry++;
      try {
        response = await _client?.send(request);
        if (response == null) break;

        if (response.statusCode >= 400) {
          final res = await Response.fromStream(response);
          response = response.rebuild(res.bodyBytes);
          final retryAfter = await customErrorHandler?.call(res, retry);
          if (retryAfter != null) {
            // wait and retry
            await Future.delayed(retryAfter);
            request = request.rebuild();
            continue;
          } else {
            id ??= _uniqueId.string();
            if (!traceRequests) _traceRequest(id, request);
            response = await _traceResponse(id, response);
          }
        } else if (traceResponses) {
          id ??= _uniqueId.string();
          response = await _traceResponse(id, response);
        }

        return response;
      } catch (ex) {
        if (ex is ClientException &&
            ex.toString().toLowerCase().contains('closed')) {
          // connection was closed, try again...
          _client?.close();
          _client = impl_.initClient(withCredentials: withCredentials);
          request = request.rebuild();
          continue;
        } else {
          rethrow;
        }
      }
    }

    if (response != null) return response;
    throw StateError('No response from ${request.url}');
  }

  @override
  void close() {
    if (_client != null) {
      dbg.trace('[DbgClient.close] closing');
      _client?.close();
      _client = null;
      super.close();
    }
  }
}

extension on BaseRequest {
  BaseRequest rebuild() {
    final copy = Request(method, url);
    copy.persistentConnection = persistentConnection;
    copy.followRedirects = followRedirects;
    copy.maxRedirects = maxRedirects;

    final self = this;
    if (self is Request) {
      copy.headers.addAll(headers);
      copy.encoding = self.encoding;
      copy.bodyBytes = self.bodyBytes;
    }

    return copy;
  }
}

extension on StreamedResponse {
  StreamedResponse rebuild(List<int> bodyBytes) => StreamedResponse(
    Stream.fromIterable([bodyBytes]),
    statusCode,
    reasonPhrase: reasonPhrase,
    contentLength: contentLength,
    headers: headers,
    isRedirect: isRedirect,
    persistentConnection: persistentConnection,
    request: request,
  );
}

extension on Map<String, String> {
  String dump(
    String Function(MapEntry<String, String>) format, {
    String sep = '\n',
  }) => entries.map(format).join(sep);
}
