import 'dart:io';

import 'package:agenteek/agenteek.dart';

import '../file_reader/file_reader.dart';
import '../file_reader/helpers.dart';
import '../file_toolset.dart';

/// Replaces selected lines of a file with new content.
///
/// - [args]: A JSON object containing the `path`, `startLine`, optional `endLine`, and `newText` fields.
///   - `path`: The path of the file to modify.
///   - `originalText`: The original text to be replaced; there must be exactly one occurrence within the original text.
///   - `newText`: The new content used as a replacement.
///
/// Returns a `Future<String>` which contains 'OK'.
Tool<String> replaceTextTool(FileToolSet toolSet) => Tool(
  name: toolSet.buildToolName('replace_text'),
  description: toolSet.buildDescription(
    'Replaces `originalText` with `newText` in a file'.sideEffect(
      'line numbers might change',
    ),
  ),
  inputSchema: _inputSchema,
  onCall: (args) => _replaceMultiText(toolSet, args),
);

Future<ToolSuccess<String>> _replaceMultiText(
  FileToolSet toolSet,
  Json args,
) async {
  var path = args.getString('path').trim();
  if (path.startsWith('/')) path = path.substring(1);
  final originalText = normalizeText(args.getString('originalText'));
  final newText = normalizeText(args.getString('newText'));
  final targetLines = args.getList<int>('targetLines', defaultValue: const []);

  // check
  final file = await File(path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied.';
  if (!await file.exists()) throw 'File not found: $path.';
  if (targetLines.length != targetLines.toSet().length) {
    throw 'Found duplicate target line numbers.';
  }

  // proceed
  var text = normalizeText(await FileReader.readString(file));
  var index = text.indexOf(originalText);
  if (index < 0) {
    throw 'Original text was not found in the file; new text was not applied.';
  }

  if (targetLines.isEmpty) {
    // single replacement
    if (text.indexOf(originalText, index + 1) >= 0) {
      throw 'Found several occurrences of original text and no target lines were specified for replacements; new text was not applied.';
    }
    text = text.replaceFirst(originalText, newText, index);
  } else {
    // multiple replacements
    final lineNumbers = <int>[-1];
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '\n') {
        lineNumbers.add(i);
      }
    }

    final occurrences = [index];
    while (index >= 0) {
      index = text.indexOf(originalText, index + 1);
      if (index < 0) break;
      occurrences.add(index);
    }

    if (targetLines.length > occurrences.length) {
      throw 'Found ${occurrences.length} occurrences of original text, which is less than the number of required replacements (${targetLines.length}); new text was not applied.';
    }

    // replace from end
    for (var i = occurrences.length - 1; i >= 0; i--) {
      final index = occurrences[i];
      for (var j = lineNumbers.length - 1; j >= 0; j--) {
        if (index > lineNumbers[j]) {
          lineNumbers.removeWhere((l) => index < l);
          final targetLine = j + 1;
          if (targetLines.contains(targetLine)) {
            text = text.replaceFirst(originalText, newText, index);
            targetLines.removeWhere((l) => l == targetLine);
          }
          break;
        }
      }
    }

    if (targetLines.isNotEmpty) {
      throw 'Failed to replace at ${targetLines.length > 1 ? 'lines' : 'line'} ${targetLines.join(', ')}; new text was not applied.';
    }
  }

  await file.writeAsString(text);
  return ToolSuccess.ok;
}

final _inputSchema = Z.object(
  properties: {
    'path': Z.string(description: 'File path'),
    'originalText': Z.string(description: 'Original text'),
    'newText': Z.string(description: 'New text'),
    'targetLines': Z.list(
      items: Z.integer(),
      description:
          'Line numbers where replacement is expected; when missing or empty, the original text will be replaced if and only if there is exactly one occurence'
              .optional(),
    ),
  },
  required: ['path', 'originalText', 'newText'],
);
