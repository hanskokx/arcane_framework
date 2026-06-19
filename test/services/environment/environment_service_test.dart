import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ArcaneEnvironmentService", () {
    late ArcaneEnvironmentService service;

    setUp(() {
      service = ArcaneEnvironmentService.I;
      service.reset();
    });

    test("singleton instance is consistent", () {
      expect(identical(ArcaneEnvironmentService.I, service), isTrue);
      expect(identical(Arcane.environment, service), isTrue);
    });

    test("default environment is normal", () {
      expect(service.current, Environment.normal);
    });

    test("setEnvironment updates current value", () {
      service.setEnvironment(Environment.debug);
      expect(service.current, Environment.debug);
    });

    test("setEnvironment with same value does not emit stream event", () async {
      var didEmit = false;
      final sub = service.environmentChanges.listen((_) {
        didEmit = true;
      });

      service.setEnvironment(Environment.normal);
      await Future<void>.delayed(Duration.zero);

      expect(didEmit, isFalse);
      await sub.cancel();
    });

    test("setEnvironment with different value emits stream event", () async {
      final event = expectLater(
        service.environmentChanges,
        emits(Environment.debug),
      );

      service.setEnvironment(Environment.debug);
      await event;
    });

    test("notifier listeners are notified on changes", () {
      var notified = false;
      service.notifier.addListener(() {
        notified = true;
      });

      service.setEnvironment(Environment.debug);
      expect(notified, isTrue);
    });

    test("enableDebugMode and disableDebugMode switch built-in modes", () {
      service.enableDebugMode();
      expect(service.current, Environment.debug);

      service.disableDebugMode();
      expect(service.current, Environment.normal);
    });

    test("reset restores normal and emits current state", () async {
      service.setEnvironment(Environment.debug);

      final event = expectLater(
        service.environmentChanges,
        emits(Environment.normal),
      );

      service.reset();

      expect(service.current, Environment.normal);
      await event;
    });

    test("environmentChanges works after listener cancellation", () async {
      final first = service.environmentChanges.listen((_) {});
      await first.cancel();

      final event = expectLater(
        service.environmentChanges,
        emits(Environment.debug),
      );

      service.setEnvironment(Environment.debug);
      await event;
    });

    test("dispose closes stream and subsequent reads recreate it", () async {
      service.dispose();

      final event = expectLater(
        service.environmentChanges,
        emits(Environment.debug),
      );

      service.setEnvironment(Environment.debug);
      await event;
    });
  });
}
