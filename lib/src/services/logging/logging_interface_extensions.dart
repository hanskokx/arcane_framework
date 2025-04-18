mixin class FileAndLineNumber {
  static String get _parts => StackTrace.current
      .toString()
      .split("\n")[2]
      .split(RegExp("#2"))[1]
      .trim();

  static String? get module =>
      _parts.split(".").firstOrNull?.replaceFirst("new ", "");
  static String? get method {
    if (_parts.length <= 1) return null;
    return _parts[1].split(" ").firstOrNull?.replaceAll("<anonymous", "");
  }

  static String? get fileAndLine {
    final List<String> fileAndLineParts = [
      ...?_parts.split("(package:").lastOrNull?.split(":"),
    ];

    if (fileAndLineParts.length <= 2) {
      return fileAndLineParts.firstOrNull;
    }

    return "${fileAndLineParts[0]}:${fileAndLineParts[1]}";
  }
}
