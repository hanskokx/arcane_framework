import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  setUpAll(() {
    ArcaneFeatureFlagService.I.reset();
    ArcaneAuthenticationService.I.reset();
    ArcaneReactiveTheme.I.reset();
    ArcaneEnvironmentService.I.reset();
  });

  group("Arcane", () {
    test("services getter returns all core services", () {
      final services = Arcane.services;
      expect(services, contains(isA<ArcaneFeatureFlagService>()));
      expect(services, contains(isA<ArcaneAuthenticationService>()));
      expect(services, contains(isA<ArcaneReactiveTheme>()));
      expect(services, contains(isA<ArcaneEnvironmentService>()));
    });
  });
}
