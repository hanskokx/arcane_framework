import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/material.dart";

class ArcaneApp extends StatelessWidget {
  final List<ArcaneService> services;
  final Widget child;
  const ArcaneApp({
    required this.child,
    this.services = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ArcaneEnvironmentProvider(
      child: ArcaneServiceProvider(
        serviceInstances: services,
        child: child,
      ),
    );
  }
}
