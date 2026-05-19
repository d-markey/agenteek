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
    'Replaces `originalText` with `newText` in file at `path`; '
            'multiple replacements are possible by providing the target starting lines with `targetLines` (1-based line numbers -- always call `read_file` with `mode=numbered` to get the correct line numbers)'
        .sideEffect('line numbers and file contents will change'),
  ),
  inputSchema: ReplaceTextArgs.schema,
  onCall: (args) => _replaceMultiText(toolSet, ReplaceTextArgs(args)),
);

Future<ToolSuccess<String>> _replaceMultiText(
  FileToolSet toolSet,
  ReplaceTextArgs args,
) async {
  // check
  final file = await File(
    args.path,
  ).check<File>(toolSet.root, includeHidden: toolSet.showHiddenFiles);
  if (!await file.exists()) {
    throw 'File not found: "${toolSet.getLocalPath(file)}"';
  }
  if (args.targetLines.length != args.targetLines.toSet().length) {
    throw 'Found duplicate target line numbers: ${args.targetLines}';
  }
  final originalText = args.originalText, newText = args.newText;
  if (newText == originalText) {
    throw 'New text and original text are the same: no changes made.';
  }

  // proceed
  var text = (await FileReader.readString(file));
  var index = text.indexOf(originalText);
  if (index < 0) {
    throw 'Original text was not found in the file; no changes made.';
  }

  final targetLines = args.targetLines.toList();
  if (targetLines.isEmpty) {
    // single replacement
    if (text.indexOf(originalText, index + 1) >= 0) {
      throw 'Found several occurrences of original text and no target lines were specified for replacements; no changes made.';
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
      throw 'Found ${occurrences.length} occurrences of original text, which is less than the number of required replacements (${targetLines.length}); no changes made.';
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
      throw 'No match found for target ${targetLines.length > 1 ? 'lines' : 'line'} ${targetLines.join(', ')}; no changes made.';
    }
  }

  await file.writeAsString(text);
  return ToolSuccess(
    'Text replaced with new text in file: "${file.getLocalPath(toolSet.root)}" (${(args.targetLines.isEmpty || args.targetLines.length == 1) ? '1 replacement' : '${args.targetLines.length} replacements'})',
  );
}
