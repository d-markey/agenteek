import 'dart:convert';

import 'package:web/web.dart' as web;

class PromptHistory {
  PromptHistory() {
    try {
      final str = web.window.sessionStorage.getItem(_kPromptHistoryKey);
      if (str != null) {
        final json = jsonDecode(str);
        if (json is List) {
          _promptHistory.addAll(json.map((i) => i.toString()));
        }
      }
    } catch (_) {}
  }

  static const _kPromptHistoryKey = 'agenteek_prompt_history';

  /// In-memory history of submitted prompts (oldest first).
  /// Loaded from [sessionStorage] on startup and persisted after every submit.
  final _promptHistory = <String>[];

  /// Current navigation position within [_promptHistory].
  /// Points past the end when no history item is selected.
  int _historyCursor = -1;

  /// Temporary buffer that holds the draft text while the user navigates
  /// through history, so it can be restored when they press ArrowDown back
  /// to the "new" position.
  String _historyDraft = '';

  void init(String draft) {
    if (_historyCursor < 0) {
      _historyDraft = draft.trim();
      _historyCursor = _promptHistory.length;
    }
  }

  void push(String prompt) {
    _historyDraft = '';
    _historyCursor = -1;
    prompt = prompt.trim();
    if (prompt.isEmpty) return;
    for (var i = _promptHistory.length - 1; i >= 0; i--) {
      if (_promptHistory[i] == prompt) {
        _promptHistory.removeAt(i);
        break;
      }
    }
    _promptHistory.add(prompt);
    try {
      web.window.sessionStorage.setItem(
        _kPromptHistoryKey,
        jsonEncode(_promptHistory),
      );
    } catch (_) {}
  }

  String next() {
    if (_promptHistory.isEmpty) return _historyDraft;
    if (_historyCursor == _promptHistory.length) {
      _historyCursor = 0;
      return _historyDraft;
    } else {
      return _promptHistory[_historyCursor++];
    }
  }

  String prev() {
    if (_promptHistory.isEmpty) return _historyDraft;
    if (_historyCursor == 0) {
      _historyCursor = _historyDraft.length - 1;
      return _historyDraft;
    } else {
      return _promptHistory[_historyCursor--];
    }
  }
}
