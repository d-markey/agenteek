import 'dart:io' as io;
import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_tickets/src/tickets_server.dart';

void main(List<String> args) {
  var owner = '', root = '', logger = null as ErrorSink?;
  for (var arg in args) {
    final larg = arg.toLowerCase();
    if (larg.startsWith('--owner=')) {
      owner = arg.substring('--owner='.length).trim();
    } else if (larg.startsWith('--root=')) {
      root = arg.substring('--root='.length).trim();
    } else if (larg == '--debug') {
      logger = ErrorSink('tickets/$owner')..enable();
    } else if (larg == '--help') {
      usage();
    } else {
      usage('Unknown argument: "$arg".');
    }
  }

  if (owner.isEmpty) usage('Missing owner name.');
  if (root.isEmpty) usage('Missing root folder for tickets.');

  TicketsMcpServer(
    owner,
    PersistentFileSystem(root),
    stdioChannel(input: io.stdin, output: io.stdout),
    protocolLogSink: logger,
  );
}

Never usage([String message = '']) {
  if (message.isNotEmpty) print('ERROR: $message');
  print('\nUsage: dart run example/main.dart --owner=<OWNER> --root=<PATH>\n');
  exit(message.isEmpty ? 0 : -1);
}
