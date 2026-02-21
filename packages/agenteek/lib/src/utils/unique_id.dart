import 'dart:math';

final _rnd = Random.secure().nextInt;

class UniqueIdGenerator {
  UniqueIdGenerator();

  final _ids = <int>{};

  int next() {
    while (true) {
      final id = _rnd(0x100000000);
      if (_ids.add(id)) return id;
    }
  }

  static final _str =
      '0123456789'
              'abcdefghijklmnopqrstuvwxyz'
              'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          .split('');
  static final _len = _str.length;
  String _nextChar(dynamic _) => _str[_rnd(_len)];

  final _strings = <String>{};

  String string([int length = 6]) {
    while (true) {
      final id = Iterable.generate(length, _nextChar).join();
      if (_strings.add(id)) return id;
    }
  }
}
