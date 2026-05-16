import 'package:logging/logging.dart';

class Accumulator {
  Accumulator(this.mode);

  Logger get _logger =>
      Logger('agenteek.agent.accumulator.${mode.toLowerCase()}');

  final String mode;

  final _lines = <String, int>{};
  String _partial = '';

  bool accumulate(String chunk) {
    var res = false;
    _partial += chunk;
    final lines = _partial.split('\n');
    _partial = lines.removeLast();
    for (var line in lines.where(_shouldKeepLine)) {
      line = line.trim().toLowerCase();
      final count = (_lines[line] ?? 0) + 1;
      _lines[line] = count;
      res |= (count > 4);
    }
    return res;
  }

  (int, int) checkRepetitions() {
    final entries = _lines.entries.where((e) => e.value > 4).toList()
      ..sort((a, b) {
        final countDelta = b.value.compareTo(a.value);
        return (countDelta == 0)
            ? a.key.length.compareTo(b.key.length)
            : countDelta;
      });
    if (entries.any((e) => e.value > 20)) {
      _logger.info(
        'TOP 5 ${mode.toUpperCase()}:\n'
        '${entries.take(5).map((e) => ' - (${e.value}) ${e.key}').join('\n')}',
      );
    }
    return (
      entries.where((e) => e.value > 20).length,
      entries.where((e) => e.value > 100).length,
    );
  }

  static final _wordBoundary = RegExp(r'\b');
  static final _digit = RegExp(r'[0-9]');
  static final _hexNumber = RegExp(r'^(0x)?[a-fA-F0-9_]+$');
  static final _word = RegExp(r'^[0-9\w]+$');

  static bool _shouldKeepLine(String line) {
    final parts = line.trim().split(_wordBoundary);
    for (var i = parts.length - 1; i >= 0; i--) {
      final p = parts[i].trim();
      if (p.isEmpty) {
        parts.removeAt(i);
      } else if (_digit.hasMatch(p) && _hexNumber.hasMatch(p)) {
        parts.removeAt(i);
      } else if (!_word.hasMatch(p)) {
        parts.removeAt(i);
      }
    }
    return parts.length > 2;
  }
}
