import 'toolset.dart';

mixin Prefix on ToolSet {
  String get prefix;

  String buildToolName(String toolName) =>
      prefix.isEmpty ? toolName : '$prefix.$toolName';
}
