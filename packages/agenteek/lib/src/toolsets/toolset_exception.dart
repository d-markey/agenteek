import 'tool.dart';

abstract class ToolSetException implements Exception {
  ToolSetException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class ToolNotFoundException extends ToolSetException {
  ToolNotFoundException._(super.message);

  factory ToolNotFoundException(
    String toolName,
    Iterable<Tool> availableTools,
  ) {
    toolName = toolName.toLowerCase();
    var candidates = availableTools.where(
      (tool) => tool.name.toLowerCase().contains(toolName),
    );
    if (candidates.length == 1) {
      return ToolNotFoundException._(
        'Tool "$toolName" was not found. Did you mean ${candidates.single.name}?',
      );
    } else {
      final String candidatesLabel;
      if (candidates.isEmpty) {
        candidates = availableTools;
        candidatesLabel = 'List of available tools';
      } else {
        candidatesLabel = 'Possible candidates';
      }
      return ToolNotFoundException._(
        'Tool "$toolName" was not found. $candidatesLabel: ${candidates.map((t) => t.name).join(', ')}.',
      );
    }
  }
}

class MissingArgumentException extends ToolSetException {
  final String argumentName;

  MissingArgumentException(this.argumentName)
    : super('Argument "$argumentName" is required but was not found.');
}

class InvalidArgumentException extends ToolSetException {
  final String argumentName;
  final String expectedType;

  InvalidArgumentException(this.argumentName, this.expectedType)
    : super('Argument "$argumentName" expected to be of type $expectedType.');
}
