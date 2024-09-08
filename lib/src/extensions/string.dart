extension Nullability on String? {
  bool get isNotNullOrEmpty => !isNullOrEmpty;
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
}
