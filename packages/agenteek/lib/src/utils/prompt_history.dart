import 'dart:collection';

class PromptHistory {
  PromptHistory([List<String>? history]) : _history = history ?? <String>[];

  /// In-memory history of submitted prompts (oldest first).
  final List<String> _history;

  /// Unmodifiable view of the history.
  late final history = UnmodifiableListView(_history);

  /// Current navigation position within [_history].
  /// Points past the end when no history item is selected.
  int _cursor = -1;

  /// Temporary buffer that holds the draft text while the user navigates
  /// through history, so it can be restored when they press ArrowDown back
  /// to the "new" position.
  String _draft = '';

  /// Initialize the prompt history with the given draft.
  void init(String draft) {
    if (_cursor < 0) {
      _draft = draft.trim();
      _cursor = _history.length;
    }
  }

  /// Reset the prompt history.
  void reset() {
    _cursor = -1;
    _draft = '';
  }

  /// Push a prompt to the history.
  void push(String prompt) {
    reset();
    prompt = prompt.trim();
    if (prompt.isEmpty) return;
    _history.removeWhere(($) => $ == prompt);
    _history.add(prompt);
  }

  /// Get the next prompt in the history.
  String next() {
    if (_history.isEmpty) return _draft;
    _cursor++;
    if (_cursor == _history.length) return _draft;
    if (_cursor > _history.length) _cursor = 0;
    return _history[_cursor];
  }

  /// Get the previous prompt in the history.
  String prev() {
    if (_history.isEmpty) return _draft;
    _cursor--;
    if (_cursor == -1) return _draft;
    if (_cursor < -1) _cursor = _history.length - 1;
    return _history[_cursor];
  }
}
