/// A value object representing the current application environment.
///
/// Built-in values are available through [Environment.debug] and
/// [Environment.normal], but custom values can be created for app-specific
/// environments such as `staging`.
class Environment {
  /// Creates an environment with a human-readable [name].
  const Environment(this.name);

  /// Built-in debug environment for development and testing purposes.
  static const Environment debug = Environment("debug");

  /// Built-in normal environment for production use.
  static const Environment normal = Environment("normal");

  /// Human-readable environment name.
  final String name;

  /// Returns `true` when this environment is the built-in debug environment.
  bool get isDebug => this == debug;

  /// Returns `true` when this environment is the built-in normal environment.
  bool get isNormal => this == normal;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Environment && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => "Environment($name)";
}
