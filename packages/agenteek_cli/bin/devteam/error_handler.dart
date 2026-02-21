import 'dart:convert';
import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg show trace;

const defaultRetryDelay = Duration(seconds: 5);

Future<Duration?> errorHandler(Response res, int n) async {
  Duration? retryDelay = defaultRetryDelay * (1 << (n - 1));
  switch (res.statusCode) {
    case HttpStatus.tooManyRequests:
      // handle "429 Too Many Requests" errors
      if (res.headers['content-type']?.contains('application/json') ?? false) {
        final json = jsonDecode(res.body);

        final nodes = [];
        bool $include(dynamic item) => (item is List || item is Map);
        void $register(dynamic node) {
          if (node is Map) {
            nodes.addAll(node.values.where($include));
          } else if (node is List) {
            nodes.addAll(node.where($include));
          }
        }

        // inspect nodes for a "retryDelay" entry
        $register(json);
        while (nodes.isNotEmpty) {
          final node = nodes.removeAt(0);
          if (node is Map) {
            final delay = node['retryDelay']?.toString() ?? '';
            int? val;
            if (delay.endsWith('ms')) {
              // delay in milliseconds
              val = int.tryParse(delay.substring(0, delay.length - 2));
            } else if (delay.endsWith('s')) {
              // delay in seconds
              val = int.tryParse(delay.substring(0, delay.length - 1));
              if (val != null) val *= 1000;
            } else {
              // assume delay is in seconds
              val = int.tryParse(delay);
              if (val != null) val *= 1000;
            }
            if (val != null) {
              retryDelay = Duration(milliseconds: val);
              break;
            }
            node.values.forEach($register);
          } else if (node is List) {
            node.forEach($register);
          }
        }
      }

    case HttpStatus.serviceUnavailable:
      // handle "503 Service Unavailable" errors
      break;

    default:
      // no retry on other errors
      retryDelay = null;
  }

  dbg.trace('Error ${res.statusCode} - Waiting for $retryDelay');
  return retryDelay;
}
