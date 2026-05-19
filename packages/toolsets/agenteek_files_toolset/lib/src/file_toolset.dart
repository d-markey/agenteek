import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek_files/agenteek_files_io.dart';
import 'package:dartantic_interface/dartantic_interface.dart' as dartantic;

import 'tools/create_file.dart';
import 'tools/delete_file.dart';
import 'tools/delete_lines.dart';
import 'tools/get_line_count.dart';
import 'tools/insert_text.dart';
import 'tools/list.dart';
import 'tools/locate_file.dart';
import 'tools/read_lines.dart';
import 'tools/replace_text.dart';
import 'tools/search_text.dart';
import 'tools/update_file.dart';

/// A `ToolSet` that provides tools for interacting with the file system.
class FileToolSet extends ToolSet with Prefix, Scope {
  /// Initializes a new instance of the `FileToolSet`.
  ///
  /// This constructor sets up the toolset, registering various file-related tools
  /// based on the provided permissions.
  ///
  /// - [prefix]: Used as a namespace for the file-related tools (e.g., `file_list`, `file_search`).
  /// - [scope]: An optional description of the scope covered by this toolset, to help the LLM select the right toolset.
  /// - [root]: The root directory for file operations (optional, defaults to '.').
  /// - [allowCreate]: Flag to allow file/directory creation.
  /// - [allowReplace]: Flag to allow file modification.
  /// - [allowDelete]: Flag to allow file deletion.
  /// - [showHiddenFiles]: Flag to allow listing/showing hidden files (starting with a dot).
  FileToolSet({
    required String prefix,
    String? scope,
    String root = '.',
    this.allowCreate = false,
    this.allowReplace = false,
    this.allowDelete = false,
    this.showHiddenFiles = false,
  }) : prefix = prefix.toLowerCase().trim(),
       scope = scope?.trim() ?? '',
       root = canonicalize(root) {
    // register tools
    // register(listFilesTool(this));
    register(listTool(this));
    register(locateFileTool(this));
    // register(listDirectoriesTool(this));
    register(searchTextTool(this));
    register(readLinesTool(this));
    register(getLineCountTool(this));
    if (allowCreate) register(createFileTool(this));
    if (allowReplace) register(updateFileTool(this));
    if (allowReplace) register(replaceTextTool(this));
    if (allowReplace) register(insertTextTool(this));
    if (allowReplace) register(deleteLinesTool(this));
    if (allowDelete) register(deleteFileTool(this));
  }

  /// The prefix used as a namespace for file-related tools.
  @override
  final String prefix;

  /// A description of the scope covered by this toolset.
  @override
  final String scope;

  /// The root directory for all file operations performed by this toolset.
  final String root;

  /// A flag indicating whether file and directory creation is allowed.
  final bool allowCreate;

  /// A flag indicating whether file modification (replacing content or lines) is allowed.
  final bool allowReplace;

  /// A flag indicating whether file and directory deletion is allowed.
  final bool allowDelete;

  /// A flag indicating whether hidden files (starting with a dot) should be listed or shown.
  final bool showHiddenFiles;

  String getLocalPath(FileSystemEntity e) => e.getLocalPath(root);

  @override
  Future<Map<dartantic.ToolPart, dartantic.ToolPart>> redactObsoleteToolResults(
    Iterable<dartantic.ChatMessage> history,
  ) async {
    Map<dartantic.ToolPart, dartantic.ToolPart>? results;
    final readLinesToolName = buildToolName('read_lines');

    final readLinesCalls = history
        .expand((m) => m.toolCalls)
        .where((t) => t.toolName == readLinesToolName);

    final fileReads =
        <String, List<({bool fullRead, dartantic.ToolPart tool})>>{};
    for (var call in readLinesCalls) {
      final path = call.arguments?['path'] as String?;
      final startLine = call.arguments?['startLine'] as int? ?? 1;
      final endLine = call.arguments?['endLine'] as int?;
      if (path != null) {
        try {
          final file = await File(path).check<File>(root, includeHidden: true);
          fileReads.putIfAbsent(file.path, () => []).add((
            fullRead: startLine == 1 && endLine == null,
            tool: call,
          ));
        } catch (_) {}
      }
    }

    Iterable<dartantic.ChatMessage> $messagesWithResultFor(
      dartantic.ToolPart call,
    ) sync* {
      final callId = call.callId, toolName = call.toolName;
      for (var msg in history) {
        if (msg.toolResults.any(
          (t) => t.callId == callId && t.toolName == toolName,
        )) {
          yield msg;
        }
      }
    }

    for (var entry in fileReads.entries) {
      final readCalls = entry.value;
      if (readCalls.length < 2) continue;
      final lastCallId = readCalls
          .where(($) => $.fullRead)
          .lastOrNull
          ?.tool
          .callId;
      if (lastCallId == null) continue;
      for (var i = 0; i < readCalls.length - 1; i++) {
        final readCall = readCalls[i];
        for (var originalMessage in $messagesWithResultFor(readCall.tool)) {
          final parts = originalMessage.parts.toList();
          for (var j = 0; j < parts.length; j++) {
            final part = parts[j];
            if (part is dartantic.ToolPart &&
                part.kind == .result &&
                part.callId == readCall.tool.callId &&
                part.toolName == readCall.tool.toolName &&
                part.result is! Map<String, String>) {
              results ??= {};
              results[part] = dartantic.ToolPart.result(
                callId: part.callId,
                toolName: part.toolName,
                result: {
                  'obsolete':
                      '[Content Hidden: File was later reloaded by tool call #$lastCallId]',
                },
              );
            }
          }
        }
      }
    }

    return results ?? const {};
  }
}
