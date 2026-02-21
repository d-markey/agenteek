import 'package:agenteek/src/utils/access_control_list.dart';
import 'package:test/test.dart';

void main() {
  group('ACL', () {
    group('White-list', () {
      test('Single string', () {
        final acl = AccessControlList(whiteList: ['ok']);
        expect(acl.check('ok'), isTrue);
        expect(acl.check('also ok'), isTrue);
        expect(acl.check('not ok'), isTrue); // !! :-)
        expect(acl.check('ko'), isFalse);
        expect(acl.check('ok is ko'), isTrue); // !! :-)
        expect(acl.check('ok is not ok'), isTrue); // !! :-)
      });

      test('Multiple string', () {
        final acl = AccessControlList(whiteList: ['ok', 'good']);
        expect(acl.check('ok'), isTrue);
        expect(acl.check('good'), isTrue);
        expect(acl.check('bad'), isFalse);
      });

      test('Single Regexp', () {
        final acl = AccessControlList(whiteList: [RegExp('^.*ok\$')]);
        expect(acl.check('ok'), isTrue);
        expect(acl.check('also ok'), isTrue);
        expect(acl.check('not ok'), isTrue); // !! :-)
        expect(acl.check('ko'), isFalse);
        expect(acl.check('ok is ko'), isFalse);
        expect(acl.check('ok is not ok'), isTrue); // !! :-)
      });
    });

    group('Black-list', () {
      test('Strings', () {
        final acl = AccessControlList(blackList: ['ko']);
        expect(acl.check('ok'), isTrue);
        expect(acl.check('also ok'), isTrue);
        expect(acl.check('not ok'), isTrue); // !! :-)
        expect(acl.check('ko'), isFalse);
        expect(acl.check('still ko'), isFalse);
        expect(acl.check('ko allowed'), isFalse);
      });

      test('Regexps', () {
        final acl = AccessControlList(blackList: [RegExp('^.*ko\$')]);
        expect(acl.check('ok'), isTrue);
        expect(acl.check('also ok'), isTrue);
        expect(acl.check('not ok'), isTrue); // !! :-)
        expect(acl.check('ko'), isFalse);
        expect(acl.check('still ko'), isFalse);
        expect(acl.check('ko allowed'), isTrue); // !! :-)
      });
    });

    group('Mixed', () {
      test('Strings', () {
        final acl = AccessControlList(whiteList: ['ok'], blackList: ['not ok']);
        expect(acl.check('ok'), isTrue);
        expect(acl.check('also ok'), isTrue);
        expect(acl.check('not ok'), isFalse);
        expect(acl.check('ko'), isFalse);
        expect(acl.check('still ko'), isFalse);
      });

      test('Regexps', () {
        final acl = AccessControlList(
          whiteList: ['applications', 'quality', 'stats'],
          blackList: [RegExp('^sources')],
        );
        expect(acl.check('applications'), isTrue);
        expect(acl.check('applications_transactions'), isTrue);
        expect(acl.check('stats'), isTrue);
        expect(acl.check('applications_quality_insights'), isTrue);
        expect(acl.check('quality_insights'), isTrue);

        expect(acl.check('architectural_graph'), isFalse);
        expect(acl.check('data_graph_graph_focus'), isFalse);
        expect(acl.check('source_file_details'), isFalse);
      });
    });
  });
}
