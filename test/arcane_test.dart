import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/mockito.dart";

class MockLoggingInterface extends Mock implements LoggingInterface {}

void main() {
  setUpAll(() {
    ArcaneFeatureFlags.I.reset();
    ArcaneAuthenticationService.I.reset();
    ArcaneReactiveTheme.I.reset();
  });

  group("Arcane", () {
    test("services getter returns all core services", () {
      final services = Arcane.services;
      expect(services, contains(isA<ArcaneFeatureFlags>()));
      expect(services, contains(isA<ArcaneAuthenticationService>()));
      expect(services, contains(isA<ArcaneReactiveTheme>()));
    });
  });
}
