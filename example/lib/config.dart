enum Feature {
  logging(true),
  authentication(true),
  ;

  final bool enabledAtStartup;
  const Feature(this.enabledAtStartup);
}
