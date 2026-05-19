import 'dart:convert';
import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../dart_toolset.dart';
import '_json_arguments.dart';

// test
Tool<Json> testTool(DartToolSet toolSet) => Tool(
  name: toolSet.buildToolName('test'),
  description: toolSet.buildDescription('Runs unit tests'),
  inputSchema: TestArgs.schema,
  onCall: (args) => _test(toolSet, TestArgs(args)),
);

Future<ToolSuccess<Json>> _test(DartToolSet toolSet, TestArgs args) async {
  FileSystemEntity fileOrDir;
  if (args.path.isEmpty) {
    fileOrDir = Directory(toolSet.root);
  } else {
    fileOrDir = await Link(args.path).check(toolSet.root, includeHidden: false);
    if (!await fileOrDir.exists()) {
      throw 'File or directory not found: "${fileOrDir.getLocalPath(toolSet.root)}"';
    }
  }

  final testFileOrDir = fileOrDir
      .getLocalPath(toolSet.root)
      .replaceAll('\\', '/');
  final concurrency = '--concurrency=${args.concurrency}';
  final plainName = args.nameFilter.isNotEmpty
      ? '--plain-name="${args.nameFilter}"'
      : '';

  toolSet.logger.info('Runing tests: $args');

  final result = await toolSet.execInPodman(
    'dart test --reporter=json $concurrency $plainName "$testFileOrDir"',
    timeout: Duration(seconds: args.timeout),
  );
  final testResult = _summarize(result['stdout'] as String?).trim();
  result['stdout'] = testResult;
  toolSet.logger.info(result);
  return ToolSuccess(result);
}

String _summarize(String? testReport) {
  if (testReport == null) return '';

  final lines = testReport
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty);

  // load info from test report
  final allSuites = <int, _Suite>{},
      allGroups = <int, _Group>{},
      allTests = <int, _Test>{},
      testOutputs = <String>[];
  for (final line in lines) {
    Map? entry;
    try {
      entry = jsonDecode(line);
    } catch (_) {}

    final type = entry?['type']?.toString().trim().toLowerCase() ?? '';
    if (type == 'start' || type == 'allsuites' || type == 'done') {
      // ignore start message
      continue;
    }

    var suite = _Suite.fromJson((type == 'suite') ? (entry?['suite']!) : null);
    if (suite != null) {
      allSuites[suite.id] = suite;
      continue;
    }

    var group = _Group.fromJson((type == 'group') ? (entry?['group']!) : null);
    if (group != null) {
      final groupEntry = entry?['group'] as Map;
      allGroups[group.id] = group;
      suite = allSuites[groupEntry['suiteID']]!;
      group.suite = suite;
      suite.groups.add(group);
      final parent = allGroups[groupEntry['parentID']];
      if (parent != null) {
        group.parent = parent;
        parent.groups.add(group);
      }
      continue;
    }

    var test = _Test.fromJson((type == 'teststart') ? (entry?['test']) : null);
    if (test != null) {
      final testEntry = entry?['test'] as Map;
      allTests[test.id] = test;
      test.suite = allSuites[testEntry['suiteID']];
      final groupIds = (testEntry['groupIDs'] as List?)?.cast<int>();
      if (groupIds != null && groupIds.isNotEmpty) {
        for (final groupId in groupIds.cast<int>()) {
          allGroups[groupId]!.tests.add(test);
        }
      }
      continue;
    }

    test = allTests[entry?['testID']];
    if (test != null) {
      entry as Map;
      final message = entry['message']?.toString().trim();
      if (message != null) test.messages.add(message);

      final result = entry['result']?.toString().trim().toLowerCase() ?? '';
      if (result.contains('error')) {
        test.failed = 1;
      } else if (result.contains('success')) {
        test.passed = 1;
      }

      final skipped = entry['skipped'] as bool? ?? false;
      if (skipped) {
        test.passed = 0;
        test.failed = 0;
        test.skipped = 1;
      }

      final error = entry['error']?.toString().trim();
      if (error != null) {
        test.passed = 0;
        test.failed = 1;
        test.skipped = 0;
        test.error = error;
        final st = entry['stackTrace']?.toString().trim() ?? '';
        if (st.isNotEmpty) test.stackTrace = st;
      }
      continue;
    }

    // log any "random" test output
    testOutputs.add(line);
  }

  for (final group in allGroups.values) {
    for (var i = group.tests.length - 1; i >= 0; i--) {
      final test = group.tests[i];
      if (group.groups.any((g) => g.tests.contains(test))) {
        // test is defined in a subgroup, remove it
        group.tests.removeAt(i);
      } else {
        // test belongs to this group, set it
        test.group = group;
      }
    }
  }

  var nbPassed = 0, nbFailed = 0, nbSkipped = 0;
  final sb = StringBuffer();
  for (var t in allTests.values) {
    if (t.skipped == 1) {
      nbSkipped++;
      sb.writeln(
        'SKIPPED TEST "${t.name}" FROM "${t.suite?.path ?? '<unknown test file>'}" ON PLATFORM "${t.suite?.platform ?? '<unknown platform>'}"',
      );
      continue;
    } else if (t.passed == 1) {
      nbPassed++;
      continue;
    } else if (t.failed == 1) {
      nbFailed++;
      sb.writeln(
        'FAILED TEST "${t.name}" FROM "${t.suite?.path ?? '<unknown test file>'}" ON PLATFORM "${t.suite?.platform ?? '<unknown platform>'}"',
      );
      var blankline = '';
      if (t.messages.isNotEmpty) {
        sb.writeln('Test messages:');
        sb.writeln(t.messages.map((l) => '- $l').join('\n'));
        blankline = '\n';
      }
      if ((t.error ?? '').isNotEmpty) {
        sb.writeln('Error message:');
        sb.writeln(
          t.error
              ?.split('\n')
              .where((l) => l.trim().isNotEmpty)
              .map((l) => '  $l')
              .join('\n'),
        );
        blankline = '\n';
      }
      if ((t.stackTrace ?? '').isNotEmpty) {
        sb.writeln('Stack trace:');
        sb.writeln(
          t.stackTrace
              ?.split('\n')
              .where((l) => l.trim().isNotEmpty)
              .map((l) => '> $l')
              .join('\n'),
        );
        blankline = '\n';
      }
      sb.write(blankline);
    } else if (t.failed == 0 && t.passed == 0 && t.skipped == 0) {
      sb.writeln(
        'STILL PENDING TEST "${t.name}" FROM "${t.suite?.path ?? '<unknown test file>'}" ON PLATFORM "${t.suite?.platform ?? '<unknown platform>'}"',
      );
      var blankline = '';
      if (t.messages.isNotEmpty) {
        sb.writeln('Test messages:');
        sb.writeln(t.messages.map((l) => '- $l').join('\n'));
        blankline = '\n';
      }
      sb.write(blankline);
    }
  }

  if (testOutputs.isNotEmpty) {
    sb.writeln('Additional test outputs:');
    sb.writeln(testOutputs.map((l) => ' * $l\n').join(''));
  }

  sb.writeln(
    '\nSUMMARY: ${allTests.length} tests: $nbPassed passed, $nbFailed failed, $nbSkipped skipped\n',
  );
  return sb.toString();
}

class _Suite {
  _Suite(this.id, this.platform, this.path);

  static _Suite? fromJson(Json? json) => (json == null)
      ? null
      : _Suite(
          json['id'] as int,
          json['platform'] as String? ?? '',
          json['path'] as String? ?? '',
        );

  final int id;
  final String platform;
  final String path;

  final List<_Group> groups = [];
}

class _Group {
  _Group(this.id, this.name);

  static _Group? fromJson(Json? json) => (json == null)
      ? null
      : _Group(json['id'] as int, json['name'] as String? ?? '');

  final int id;
  final String name;

  _Group? parent;
  _Suite? suite;

  final List<_Group> groups = [];
  final List<_Test> tests = [];
}

class _Test {
  _Test(this.id, this.name);

  static _Test? fromJson(Json? json) => (json == null)
      ? null
      : _Test(json['id'] as int, json['name'] as String? ?? '');

  final int id;
  final String name;

  final messages = <String>[];

  _Suite? suite;
  _Group? group;

  int passed = 0;
  int failed = 0;
  int skipped = 0;

  String? error;
  String? stackTrace;
}
