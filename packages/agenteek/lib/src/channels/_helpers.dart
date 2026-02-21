Duration? parseRetryAfter(String retryAfter) {
  final secs = int.tryParse(retryAfter);
  if (secs != null) {
    return Duration(seconds: secs);
  } else {
    const months = 'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec';
    final datePattern = RegExp(
      '(mon|tue|wed|thu|fri|sat|sun), (\\d+) ($months) (\\d+) (\\d+):(\\d+):(\\d+) GMT',
      caseSensitive: false,
    );

    final match = datePattern.firstMatch(retryAfter);
    if (match != null) {
      final day = int.tryParse(match.group(2) ?? '');
      final month = months.indexOf(match.group(3)?.toLowerCase() ?? '');
      final year = int.tryParse(match.group(4) ?? '');
      final hh = int.tryParse(match.group(5) ?? '');
      final mm = int.tryParse(match.group(6) ?? '');
      final ss = int.tryParse(match.group(7) ?? '');
      if (day != null &&
          month >= 0 &&
          year != null &&
          hh != null &&
          mm != null &&
          ss != null) {
        final date = DateTime.utc(year, (month + 4) ~/ 4, day, hh, mm, ss);
        return date.difference(DateTime.now());
      }
    }
  }

  return null;
}
