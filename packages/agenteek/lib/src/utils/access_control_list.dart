class AccessControlList {
  const AccessControlList._({
    List<Pattern> whiteList = const [],
    List<Pattern> blackList = const [],
  }) : _whiteList = whiteList,
       _blackList = blackList;

  factory AccessControlList({
    Iterable<Pattern> whiteList = const [],
    Iterable<Pattern> blackList = const [],
  }) => (whiteList.isEmpty && blackList.isEmpty)
      ? allowAll
      : AccessControlList._(
          whiteList: whiteList.toList(),
          blackList: blackList.toList(),
        );

  static const allowAll = AccessControlList._();

  final List<Pattern> _whiteList;
  final List<Pattern> _blackList;

  bool check(String name) {
    // black list has precedence
    if (_blackList.any((p) => p.allMatches(name).isNotEmpty)) {
      return false;
    }
    // if a white list is provided, only allow matching items
    if (_whiteList.isNotEmpty) {
      return _whiteList.any((p) => p.allMatches(name).isNotEmpty);
    }
    // no restrictions
    return true;
  }

  String audit(String name) {
    // black list has precedence
    final patterns = _blackList.where((p) => p.allMatches(name).isNotEmpty);
    if (patterns.isNotEmpty) {
      return '$name: blacklisted by ${patterns.map((p) => '"$p"').join(', ')}';
    }
    // if a white list is provided, only matching items are allowed
    if (_whiteList.isNotEmpty) {
      final patterns = _whiteList.where((p) => p.allMatches(name).isNotEmpty);
      return patterns.isEmpty
          ? '$name: not whitelisted by ${_whiteList.map((p) => '"$p"').join(', ')}'
          : '$name: whitelisted by ${patterns.map((p) => '"$p"').join(', ')}';
    }
    // no restrictions
    return '$name: no restriction';
  }

  @override
  String toString() {
    if (_whiteList.isEmpty) {
      return _blackList.isEmpty
          ? '$runtimeType: allow all'
          : '$runtimeType: allow all except ${_blackList.join(', ')}';
    } else {
      return _blackList.isEmpty
          ? '$runtimeType: only allow ${_whiteList.join(', ')}'
          : '$runtimeType: only allow ${_whiteList.join(', ')} unless ${_blackList.join((', '))}';
    }
  }
}
