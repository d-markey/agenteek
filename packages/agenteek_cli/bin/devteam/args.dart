class Args {
  Args._(
    this.secretsPath,
    this._teamConfPath,
    this._promptPath,
    this.usage,
    this.unknown,
  );

  final String secretsPath;
  final bool usage;
  final List<String> unknown;

  String _teamConfPath;
  String get teamConfPath => _teamConfPath;

  void overrideTeamConfPath(String teamConfPath) =>
      _teamConfPath = teamConfPath;

  String _promptPath;
  String get promptPath => _promptPath;

  void overridePromptPath(String promptPath) => _promptPath = promptPath;

  static Args parse(List<String> arguments) {
    var secretsPath = '', teamConfPath = '', promptPath = '', usage = false;
    final unknown = <String>[];

    // read command line args
    for (var arg in arguments) {
      final larg = arg.toLowerCase();
      if (larg.startsWith('--secrets:')) {
        secretsPath = arg.substring('--secrets:'.length).trim();
      } else if (larg.startsWith('--team-conf:')) {
        teamConfPath = arg.substring('--team-conf:'.length).trim();
      } else if (larg.startsWith('--prompt:')) {
        promptPath = arg.substring('--prompt:'.length).trim();
      } else if (larg == '--help' || larg == '-h') {
        usage = true;
      } else {
        unknown.add(arg);
      }
    }

    return Args._(secretsPath, teamConfPath, promptPath, usage, unknown);
  }
}
