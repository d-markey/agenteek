import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;

extension ChatMessageExt on dartantic.ChatMessage {
  dartantic.ChatMessage compact() {
    if (parts.any(_isToolOrThinking)) {
      return dartantic.ChatMessage(
        role: role,
        parts: parts.where((p) => !_isToolOrThinking(p)).toList(),
        metadata: metadata,
        finishStatus: finishStatus,
      );
    } else {
      return this;
    }
  }

  bool get isEmpty => parts.isEmpty;

  static bool _isToolOrThinking(dartantic.StandardPart part) =>
      part is dartantic.ToolPart || part is dartantic.ThinkingPart;
}
