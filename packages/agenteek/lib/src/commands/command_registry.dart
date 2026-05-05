import 'command.dart';

/// A registry for [Command]s, indexed by their names and aliases.
class CommandRegistry {
  final Map<String, Command> _commands = {};

  /// Registers a [Command] and its aliases.
  void register(Command command) {
    _commands[command.name.toLowerCase()] = command;
    for (final alias in command.aliases) {
      _commands[alias.toLowerCase()] = command;
    }
  }

  /// Looks up a [Command] by its [label] (name or alias).
  ///
  /// The [label] is matched case-insensitively and handles optional leading slash.
  Command? lookup(String label) {
    if (label.isEmpty) return null;
    final cleanLabel = label.startsWith('/') ? label.substring(1) : label;
    return _commands[cleanLabel.toLowerCase()];
  }

  /// Returns all unique [Command]s in the registry.
  Iterable<Command> get all => _commands.values.toSet();
}
