import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';

import '../file_toolset.dart';
import '_json_arguments.dart';

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
  inputSchema: ReplaceTextArgs.schema,
  onCall: (args) => _replaceMultiText(toolSet, ReplaceTextArgs(args)),
);

Future<ToolSuccess<String>> _replaceMultiText(
  FileToolSet toolSet,
  ReplaceTextArgs args,
) async {
  // check
  final file = await File(args.path).check<File>(toolSet.root);
  if (!toolSet.showHiddenFiles && file.isHidden) throw 'Access denied.';
  if (!await file.exists()) throw 'File not found: ${args.path}.';
  if (args.targetLines.length != args.targetLines.toSet().length) {
    throw 'Found duplicate target line numbers.';
  }
  final originalText = args.originalText, newText = args.newText;
  if (newText == originalText) {
    throw 'New text and original text are the same: no changes.';
  }

  // proceed
  var text = (await FileReader.readString(file));
  var index = text.indexOf(originalText);
  if (index < 0) {
    throw 'Original text was not found in the file; new text was not applied.';
  }

  final targetLines = args.targetLines;
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

    if (args.targetLines.length > occurrences.length) {
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
