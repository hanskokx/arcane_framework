import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  setUpAll(() async {
    Arcane.features.reset();
    await Arcane.auth.reset();
    Arcane.theme.reset();
    Arcane.environment.reset();
  });

  group("Arcane", () {
    tearDown(() {
      ArcaneServices.I.clear();
    });

    test("services getter returns all core services", () {
      final services = Arcane.services;
      expect(services, contains(isA<ArcaneFeatureFlagService>()));
      expect(services, contains(isA<ArcaneAuthenticationService>()));
      expect(services, contains(isA<ArcaneThemeService>()));
      expect(services, contains(isA<ArcaneEnvironmentService>()));
    });

    test(
      "fallback getters return singletons when registry is present but empty",
      () {
        ArcaneServices.I.clear();

        expect(Arcane.features, same(ArcaneFeatureFlagService.I));
        expect(Arcane.auth, same(ArcaneAuthenticationService.I));
        expect(Arcane.theme, same(ArcaneThemeService.I));
        expect(Arcane.environment, same(ArcaneEnvironmentService.I));
      },
    );
  });
}
