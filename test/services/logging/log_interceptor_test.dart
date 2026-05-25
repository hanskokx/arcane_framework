import "package:arcane_framework/src/services/logging/logging_service.dart";
import "package:flutter_test/flutter_test.dart";

class DummyLogEvent extends LogEvent {
  DummyLogEvent({required super.level, required super.message});
}

class DummyLoggingInterface extends LoggingInterface {
  const DummyLoggingInterface() : super();

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
  group("LogInterceptor", () {
    test("calls the callback and returns the event unchanged", () {
      final interceptor = LogInterceptor((event, context) => event);
      final event = DummyLogEvent(level: Level.info, message: "test");
      const context = LogInterceptorContext();
      final result = interceptor(event, context: context);
      expect(result, equals(event));
    });

    test("can modify the event", () {
      final interceptor = LogInterceptor((event, context) {
        return DummyLogEvent(level: Level.warning, message: event.message);
      });
      final event = DummyLogEvent(level: Level.info, message: "test");
      const context = LogInterceptorContext();
      final result = interceptor(event, context: context);
      expect(result, isA<DummyLogEvent>());
      expect(result!.level, Level.warning);
      expect(result.message, "test");
    });

    test("can suppress the event by returning null", () {
      final interceptor = LogInterceptor((event, context) => null);
      final event = DummyLogEvent(level: Level.info, message: "test");
      const context = LogInterceptorContext();
      final result = interceptor(event, context: context);
      expect(result, isNull);
    });

    test("receives the correct context", () {
      const dummyInterface = DummyLoggingInterface();
      LogInterceptorContext? receivedContext;
      final interceptor = LogInterceptor((event, context) {
        receivedContext = context;
        return event;
      });
      final event = DummyLogEvent(level: Level.info, message: "test");
      const context = LogInterceptorContext(interface: dummyInterface);
      interceptor(event, context: context);
      expect(receivedContext, isNotNull);
      expect(receivedContext!.interface, dummyInterface);
    });
  });
}
