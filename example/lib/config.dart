enum Feature {
  logging(true),
  ;

  final bool enabledAtStartup;
  const Feature(this.enabledAtStartup);
}
