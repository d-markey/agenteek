class BuildConfig {
  static const withCustomMcp = bool.fromEnvironment(
    'agenteek.with_custom_mcp',
    defaultValue: true,
  );

  static const withAutoConf = bool.fromEnvironment(
    'agenteek.with_auto_conf',
    defaultValue: false,
  );
}
