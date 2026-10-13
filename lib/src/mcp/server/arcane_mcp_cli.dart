/// Command-line interface parsing for the arcane_mcp_server executable.
library;

/// Result of parsing command-line arguments for the MCP server.
class ArcaneMcpCliResult {
  const ArcaneMcpCliResult({
    this.help = false,
    this.showVersion = false,
    this.runServer = false,
    this.errors = const <String>[],
  });

  /// Whether --help or -h was requested.
  final bool help;

  /// Whether --version was requested.
  final bool showVersion;

  /// Whether the server should be started (no flags or only recognized flags
  /// that don't imply early exit).
  final bool runServer;

  /// Any parsing errors encountered.
  final List<String> errors;
}

/// Parses command-line arguments for the arcane_mcp_server executable.
///
/// Recognized flags:
///   - --help, -h    Print usage and exit.
///   - --version     Print version and exit.
///   - --            Stop parsing flags; remaining args are ignored.
///
/// Unknown -prefixed options and stray positional arguments produce errors.
ArcaneMcpCliResult parseArcaneMcpArgs(List<String> arguments) {
  bool help = false;
  bool showVersion = false;
  final List<String> errors = <String>[];

  for (int i = 0; i < arguments.length; i++) {
    final String arg = arguments[i];
    if (arg == "--") {
      break;
    }
    switch (arg) {
      case "--help":
      case "-h":
        help = true;
      case "--version":
        showVersion = true;
      default:
        if (arg.startsWith("-")) {
          errors.add("Unknown option '$arg'.");
        } else {
          errors.add("Unknown argument '$arg'.");
        }
    }
  }

  return ArcaneMcpCliResult(
    help: help,
    showVersion: showVersion,
    runServer: !help && !showVersion && errors.isEmpty,
    errors: errors,
  );
}

/// Returns the usage text for the arcane_mcp_server executable.
String arcaneMcpUsage() {
  return "Usage: dart run arcane_framework:arcane_mcp_server [options]\n"
      "\n"
      "The MCP server for arcane_framework. Speaks MCP over stdio, discovers\n"
      "running apps via the Dart Tooling Daemon, and exposes live state through\n"
      "get_* tools and arcane://* resources.\n"
      "\n"
      "Options:\n"
      "  --help, -h       Show this help.\n"
      "  --version        Print the version.\n";
}
