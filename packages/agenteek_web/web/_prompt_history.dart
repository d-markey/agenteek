import 'dart:convert';

import 'package:web/web.dart' as web;

class PromptHistory {
  PromptHistory() {
    try {
      final str = web.window.sessionStorage.getItem(_kPromptHistoryKey);
      if (str != null) {
        final json = jsonDecode(str);
        if (json is List) {
          _history.addAll(json.map(($) => $.toString()));
        }
      }
    } catch (_) {}
  }

  static const _kPromptHistoryKey = 'agenteek_prompt_history';

  /// In-memory history of submitted prompts (oldest first).
  /// Loaded from [sessionStorage] on startup and persisted after every submit.
  final _history = <String>[];

  /// Current navigation position within [_history].
  /// Points past the end when no history item is selected.
  int _cursor = -1;

  /// Temporary buffer that holds the draft text while the user navigates
  /// through history, so it can be restored when they press ArrowDown back
  /// to the "new" position.
  String _draft = '';

  void init(String draft) {
    if (_cursor < 0) {
      _draft = draft.trim();
      _cursor = _history.length;
    }
  }

  void reset() {
    _cursor = -1;
    _draft = '';
  }

  void push(String prompt) {
    reset();
    prompt = prompt.trim();
    if (prompt.isEmpty) return;
    _history.removeWhere(($) => $ == prompt);
    _history.add(prompt);
    try {
      web.window.sessionStorage.setItem(
        _kPromptHistoryKey,
        jsonEncode(_history),
      );
    } catch (_) {}
  }

  String next() {
    if (_history.isEmpty) return _draft;
    _cursor++;
    if (_cursor == _history.length) return _draft;
    if (_cursor > _history.length) _cursor = 0;
    return _history[_cursor];
  }

  String prev() {
    if (_history.isEmpty) return _draft;
    _cursor--;
    if (_cursor < 0) {
      _cursor = _history.length;
      return _draft;
    }
    return _history[_cursor];
  }
}
