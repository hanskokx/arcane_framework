import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

class _InterceptorsTestInterface extends LoggingInterface {
  _InterceptorsTestInterface(this.name);

  final String name;

  @override
  void log(
    String message, {
    Map<String, Object?>? metadata,
    Level? level,
    StackTrace? stackTrace,
    Object? extra,
  }) {}
}

void main() {
  group("LoggingInterceptorsService", () {
    late _InterceptorsTestInterface primary;
    late _InterceptorsTestInterface secondary;
    late LogInterceptor global;
    late LogInterceptor interfaceScoped;
    late LogInterceptor typeScoped;

    setUp(() {
      Arcane.logger.reset();
      Arcane.logger.interceptors.clear();

      primary = _InterceptorsTestInterface("primary");
      secondary = _InterceptorsTestInterface("secondary");

      global = LogInterceptor((event, context) => event);
      interfaceScoped = LogInterceptor((event, context) => event);
      typeScoped = LogInterceptor((event, context) => event);
    });

    test("clearGlobal removes global interceptors only", () {
      Arcane.logger.interceptors.add(global);
      Arcane.logger.interceptors
          .registerForInterface(primary, [interfaceScoped]);

      Arcane.logger.interceptors.clearGlobal();

      final resolved = Arcane.logger.interceptors.resolveForInterface(primary);
      expect(resolved, isNot(contains(global)));
      expect(resolved, contains(interfaceScoped));
    });

    test("resolveForInterface includes only matching registrations", () {
      Arcane.logger.interceptors.add(global);
      Arcane.logger.interceptors
          .registerForInterface(primary, [interfaceScoped]);

      Arcane.logger.interceptors.add(
        typeScoped,
        matcher: (interface) => interface is _InterceptorsTestInterface,
      );

      final forPrimary =
          Arcane.logger.interceptors.resolveForInterface(primary);
      final forSecondary =
          Arcane.logger.interceptors.resolveForInterface(secondary);

      expect(forPrimary, contains(global));
      expect(forPrimary, contains(interfaceScoped));
      expect(forPrimary, contains(typeScoped));

      expect(forSecondary, contains(global));
      expect(forSecondary, isNot(contains(interfaceScoped)));
      expect(forSecondary, contains(typeScoped));
    });
  });
}
