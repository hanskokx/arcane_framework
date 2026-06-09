import "package:arcane_framework/arcane_framework.dart";
import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  setUpAll(() async {
    ArcaneFeatureFlagService.I.reset();
    await ArcaneAuthenticationService.I.reset();
    ArcaneReactiveTheme.I.reset();
    ArcaneEnvironmentService.I.reset();
  });

  group("Arcane", () {
    tearDown(() {
      Arcane.clearRegistry();
    });

    test("services getter returns all core services", () {
      final services = Arcane.services;
      expect(services, contains(isA<ArcaneFeatureFlagService>()));
      expect(services, contains(isA<ArcaneAuthenticationService>()));
      expect(services, contains(isA<ArcaneReactiveTheme>()));
      expect(services, contains(isA<ArcaneEnvironmentService>()));
    });

    test(
        "fallback getters return singletons when registry is present but empty",
        () {
      final notifier = ValueNotifier<List<ArcaneService>>(<ArcaneService>[]);
      Arcane.setRegistry(notifier);

      expect(Arcane.features, same(ArcaneFeatureFlagService.I));
      expect(Arcane.auth, same(ArcaneAuthenticationService.I));
      expect(Arcane.theme, same(ArcaneThemeService.I));
      expect(Arcane.environment, same(ArcaneEnvironmentService.I));
    });
  });
}
