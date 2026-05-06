import 'dart:async';
import 'dart:convert';

import 'package:agenteek/agenteek.dart';

import 'tools/list_topics.dart';
import 'tools/recall_topic.dart';
import 'tools/memorize_topic.dart';
import 'tools/forget_topic.dart';

/// A `ToolSet` that provides tools for managing memory.
/// The default implementation uses in-memory storage (information is lost
/// when the process exits).
class MemoryToolSet extends ToolSet with Prefix {
  /// Initializes a new instance of the `MemoryToolSet`.
  MemoryToolSet({
    required this.prefix,
    required this.owner,
    FileSystem? fileSystem,
  }) : fileSystem = fileSystem ?? MemoryFileSystem(),
       fileName = 'memory_$owner.json' {
    // register tools
    register(listTopicsTool(this));
    register(recallTopicTool(this));
    register(memorizeTopicTool(this));
    register(forgetTopicTool(this));
  }

  /// The prefix used as a namespace for file-related tools.
  @override
  final String prefix;

  final String owner;
  final FileSystem fileSystem;
  final String fileName;

  final topics = <String, String>{};

  /// Synchronizes the in-memory topics with the file on disk.
  Future<Map<String, String>> sync() async {
    if (await fileSystem.exists(fileName)) {
      final topicsData = (jsonDecode(await fileSystem.read(fileName)) as Json)
          .cast<String, String>();
      for (var entry in topicsData.entries) {
        final topic = entry.key.trim().toLowerCase();
        if (!topics.containsKey(topic)) {
          topics[topic] = entry.value;
        }
      }
    }
    return topics;
  }
}
