import 'dart:convert';

import 'package:agenteek/agenteek.dart';
import 'package:web/web.dart' as web;

class WebPromptHistory extends PromptHistory {
  WebPromptHistory._(super._history);

  /// Create a new [WebPromptHistory].
  ///
  /// [history] is loaded from the browser's `SessionStorage`, or empty if not found.
  factory WebPromptHistory() {
    List<String>? history;
    try {
      final str = web.window.sessionStorage.getItem(_kPromptHistoryKey);
      if (str != null) {
        final json = jsonDecode(str);
        if (json is List) {
          history = json.map(($) => $.toString()).toList();
        }
      }
    } catch (_) {}
    return WebPromptHistory._(history);
  }

  static const _kPromptHistoryKey = 'agenteek_prompt_history';

  @override
  void push(String prompt) {
    super.push(prompt);
    try {
      web.window.sessionStorage.setItem(
        _kPromptHistoryKey,
        jsonEncode(history),
      );
    } catch (_) {}
  }
}
