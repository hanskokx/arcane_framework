import "package:arcane_logger/arcane_logger.dart";
import "package:test/test.dart";

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
      ArcaneLogger.I.reset();
      ArcaneLogger.I.interceptors.clear();

      primary = _InterceptorsTestInterface("primary");
      secondary = _InterceptorsTestInterface("secondary");

      global = LogInterceptor((event, context) => event);
      interfaceScoped = LogInterceptor((event, context) => event);
      typeScoped = LogInterceptor((event, context) => event);
    });

    test("clearGlobal removes global interceptors only", () {
      ArcaneLogger.I.interceptors.add(global);
      ArcaneLogger.I.interceptors.registerForInterface(primary, [
        interfaceScoped,
      ]);

      ArcaneLogger.I.interceptors.clearGlobal();

      final resolved = ArcaneLogger.I.interceptors.resolveForInterface(primary);
      expect(resolved, isNot(contains(global)));
      expect(resolved, contains(interfaceScoped));
    });

    test("resolveForInterface includes only matching registrations", () {
      ArcaneLogger.I.interceptors.add(global);
      ArcaneLogger.I.interceptors.registerForInterface(primary, [
        interfaceScoped,
      ]);

      ArcaneLogger.I.interceptors.add(
        typeScoped,
        matcher: (interface) => interface is _InterceptorsTestInterface,
      );

      final forPrimary = ArcaneLogger.I.interceptors.resolveForInterface(
        primary,
      );
      final forSecondary = ArcaneLogger.I.interceptors.resolveForInterface(
        secondary,
      );

      expect(forPrimary, contains(global));
      expect(forPrimary, contains(interfaceScoped));
      expect(forPrimary, contains(typeScoped));

      expect(forSecondary, contains(global));
      expect(forSecondary, isNot(contains(interfaceScoped)));
      expect(forSecondary, contains(typeScoped));
    });
  });
}
