import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

import '_logger.stub.dart'
    if (dart.library.io) '_logger.io.dart'
    if (dart.library.js_interop) '_logger.web.dart'
    as impl_
    show trace;

void Function(Object) trace = impl_.trace;

String dump(dynamic args, {int maxLen = 40}) {
  final str = args.toString();
  return (str.length > maxLen) ? '${str.substring(0, maxLen)}...' : str;
}

extension ChatMessageDbgExt on dartantic.ChatMessage {
  String dump() {
    if (text.trim().isEmpty) {
      return '[${role.name}]:\n\n${parts.map((p) => '* part ${p.runtimeType} = ```\n${p.toJson()}\n```').join('\n')}\n';
    } else {
      return '[${role.name}]:\n\n$text\n';
    }
  }
}
