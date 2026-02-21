import 'dart:async';

import 'package:dart_mcp/stdio.dart' as mcp;
import 'package:stream_channel/stream_channel.dart';

StreamChannel<String> stdioChannel({
  required Stream<List<int>> input,
  required StreamSink<List<int>> output,
}) => mcp.stdioChannel(input: input, output: output);
