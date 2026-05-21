import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";

class TestLoggingInterface extends LoggingInterface
    with LoggingInitializationMixin {
  TestLoggingInterface(this.name, [super.feature]);

  final String name;
  int initCallCount = 0;
  final List<LogEvent> events = [];

  @override
  Future<void> init() async {
    await super.init();
    initCallCount += 1;
  }

  @override
  void log(
    String message, {
    Map<String, Object?>? metadata,
    Level? level,
    StackTrace? stackTrace,
    Object? extra,
  }) {
    events.add(
      LogEvent(
        message: message,
        metadata: metadata == null ? null : Map<String, Object?>.from(metadata),
        level: level,
        stackTrace: stackTrace,
        extra: extra,
      ),
    );
  }
}

class TestPassiveLoggingInterface extends LoggingInterface {
  TestPassiveLoggingInterface(this.name, [super.feature]);

  final String name;
  final List<LogEvent> events = [];

  @override
  void log(
    String message, {
    Map<String, Object?>? metadata,
    Level? level,
    StackTrace? stackTrace,
    Object? extra,
  }) {
    events.add(
      LogEvent(
        message: message,
        metadata: metadata == null ? null : Map<String, Object?>.from(metadata),
        level: level,
        stackTrace: stackTrace,
        extra: extra,
      ),
    );
  }
}

class RedactingLogInterceptor implements LogInterceptor {
  const RedactingLogInterceptor();

  @override
  LogEvent? call(
    LogEvent event, {
    required LogInterceptorContext context,
  }) {
    final Object? token = event.metadata?["token"];
    if (token == null) return event;

    return event.copyWith(
      metadata: {
        ...?event.metadata,
        "token": "[redacted]",
      },
    );
  }
}

void main() {
  late TestLoggingInterface myInterface;
  late LogInterceptor prefixInterceptor;

  setUp(() {
    Arcane.logger.reset();
    myInterface = TestLoggingInterface("primary");
    prefixInterceptor = LogInterceptor(
      (event, {required context}) {
        return event.copyWith(message: "[global] ${event.message}");
      },
    );
  });

  group("ArcaneLogger", () {
    group("interface management", () {
      test("registerInterfaces adds interfaces correctly", () async {
        await Arcane.logger.registerInterface(myInterface);

        expect(
          Arcane.logger.interfaces,
          contains(isA<LoggingInterface>()),
        );
      });

      test("registering an interface doesn't initialize it", () async {
        await Arcane.logger.registerInterface(myInterface);

        expect(Arcane.logger.interfaces.first, isA<LoggingInterface>());

        expect(myInterface.initialized, false);
        expect(myInterface.initCallCount, 0);
      });

      test("registering an interface initializes the logger", () async {
        expect(Arcane.logger.initialized, false);

        await Arcane.logger.registerInterface(myInterface);

        expect(Arcane.logger.initialized, true);
      });

      test("interfaces can be initialized through the logger", () async {
        await Arcane.logger.registerInterface(myInterface);

        expect(myInterface.initialized, false);

        await Arcane.logger.initializeInterfaces();

        expect(myInterface.initCallCount, 1);
      });

      test("non-initializable interfaces are skipped by initializeInterfaces",
          () async {
        final TestPassiveLoggingInterface passiveInterface =
            TestPassiveLoggingInterface("passive");

        await Arcane.logger.registerInterfaces([
          myInterface,
          passiveInterface,
        ]);

        await Arcane.logger.initializeInterfaces();

        expect(myInterface.initCallCount, 1);

        Arcane.log("hello");

        expect(myInterface.events.single.message, "hello");
        expect(passiveInterface.events.single.message, "hello");
      });

      test("multiple interfaces can be registered", () async {
        await Arcane.logger.registerInterfaces([
          TestLoggingInterface("first"),
          TestLoggingInterface("second"),
        ]);

        expect(
          Arcane.logger.interfaces,
          contains(isA<TestLoggingInterface>()),
        );
        expect(
          Arcane.logger.interfaces.length,
          2,
        );
      });

      test("global interceptors can be registered at runtime", () async {
        await Arcane.logger.registerInterface(myInterface);

        Arcane.log("before");
        Arcane.logger.registerInterceptor(prefixInterceptor);
        Arcane.log("after");

        expect(myInterface.events[0].message, "before");
        expect(myInterface.events[1].message, "[global] after");
      });

      test("interface interceptors can be registered at runtime", () async {
        final LogInterceptor dropForPrimary = LogInterceptor(
          (event, {required LogInterceptorContext context}) {
            if ((context.interface as TestLoggingInterface).name == "primary") {
              return null;
            }

            return event;
          },
        );

        await Arcane.logger.registerInterface(myInterface);

        Arcane.log("before");
        Arcane.logger.registerInterceptor(dropForPrimary);
        Arcane.log("blocked");
        Arcane.logger.unregisterInterceptor(dropForPrimary);
        Arcane.log("after");

        expect(
          myInterface.events.map((LogEvent event) => event.message),
          ["before", "after"],
        );
      });
    });

    group("persistent metadata", () {
      test("addPersistentMetadata adds metadata correctly", () {
        Arcane.logger.addPersistentMetadata({"test": "value"});
        expect(Arcane.logger.additionalMetadata["test"], equals("value"));
      });

      test("removePersistentMetadata removes specific key", () {
        Arcane.logger.addPersistentMetadata({"test": "value", "keep": "this"});
        Arcane.logger.removePersistentMetadata("test");
        expect(Arcane.logger.additionalMetadata.containsKey("test"), false);
        expect(Arcane.logger.additionalMetadata["keep"], equals("this"));
      });

      test("clearPersistentMetadata removes all metadata", () {
        Arcane.logger
            .addPersistentMetadata({"test": "value", "another": "value"});
        Arcane.logger.clearPersistentMetadata();
        expect(Arcane.logger.additionalMetadata.isEmpty, true);
      });
    });

    group("logging messages", () {
      const String logMessage = "Test";

      setUp(() async {
        await Arcane.logger.registerInterface(myInterface);
      });

      test("logging a basic message works", () async {
        Arcane.log(logMessage);

        expect(myInterface.events.single.message, logMessage);
      });

      test("logging at a different level works", () async {
        Arcane.log(
          logMessage,
          level: Level.info,
        );

        expect(myInterface.events.last.level, Level.info);

        Arcane.log(
          logMessage,
          level: Level.warning,
        );

        expect(myInterface.events.last.level, Level.warning);
      });

      test("logging a stacktrace works", () async {
        final stackTrace = StackTrace.current;
        Arcane.log(logMessage, stackTrace: stackTrace);

        expect(myInterface.events.single.stackTrace, stackTrace);
      });

      test("logging an extra object works", () async {
        const bool extraObject = true;
        Arcane.log(
          logMessage,
          extra: extraObject,
        );

        expect(myInterface.events.single.extra, extraObject);
      });

      test("logging metadata works", () async {
        final Map<String, String> metadata = {"test": "value"};
        Arcane.log(
          logMessage,
          metadata: metadata,
        );

        expect(myInterface.events.single.metadata?["test"], "value");
        expect(
          myInterface.events.single.metadata?.containsKey("timestamp"),
          true,
        );
      });

      test("global interceptors run in registration order", () async {
        Arcane.logger.registerInterceptors([
          LogInterceptor((event, {required context}) {
            expect(context.interface, same(myInterface));
            return event.copyWith(message: "${event.message}:first");
          }),
          LogInterceptor((event, {required context}) {
            expect(context.interface, same(myInterface));
            return event.copyWith(message: "${event.message}:second");
          }),
        ]);

        Arcane.log(logMessage);

        expect(myInterface.events.single.message, "Test:first:second");
      });

      test("global interceptors can drop events for all interfaces", () async {
        await Arcane.logger.registerInterface(myInterface);
        Arcane.logger.registerInterceptor(
          LogInterceptor((event, {required context}) => null),
        );

        Arcane.log(logMessage);

        expect(myInterface.events, isEmpty);
      });

      test("custom interceptor classes can implement LogInterceptor", () async {
        Arcane.logger.registerInterceptor(const RedactingLogInterceptor());

        Arcane.log(
          logMessage,
          metadata: {"token": "secret-token"},
        );

        expect(
          myInterface.events.single.metadata?["token"],
          "[redacted]",
        );
      });

      test("interface interceptors can drop events per destination", () async {
        final TestLoggingInterface secondaryInterface =
            TestLoggingInterface("secondary");
        final LogInterceptor allowPrimaryOnly = LogInterceptor(
          (event, {required LogInterceptorContext context}) {
            final String name =
                (context.interface as TestLoggingInterface).name;
            return name == "primary" ? event : null;
          },
        );

        Arcane.logger.registerInterceptor(allowPrimaryOnly);
        await Arcane.logger.registerInterface(
          secondaryInterface,
        );

        Arcane.log(logMessage);

        expect(myInterface.events.single.message, logMessage);
        expect(secondaryInterface.events, isEmpty);
      });

      test("interface interceptors receive the current interface", () async {
        final TestLoggingInterface secondaryInterface =
            TestLoggingInterface("secondary");

        Arcane.logger.registerInterceptor(
          LogInterceptor((event, {required context}) {
            final TestLoggingInterface currentInterface =
                context.interface! as TestLoggingInterface;
            return event.copyWith(
              metadata: {
                ...?event.metadata,
                "target": currentInterface.name,
              },
            );
          }),
        );
        await Arcane.logger.registerInterface(
          secondaryInterface,
        );

        Arcane.log(logMessage);

        expect(myInterface.events.single.metadata?["target"], "primary");
        expect(
          secondaryInterface.events.single.metadata?["target"],
          "secondary",
        );
      });

      test("interface interceptors cannot mutate sibling interface events",
          () async {
        final TestLoggingInterface secondaryInterface =
            TestLoggingInterface("secondary");

        Arcane.logger.registerInterceptor(
          LogInterceptor((event, {required context}) {
            event.metadata?["mutatedBy"] =
                (context.interface as TestLoggingInterface).name;
            return event;
          }),
        );
        await Arcane.logger.registerInterface(
          secondaryInterface,
        );

        Arcane.log(
          logMessage,
          metadata: {"test": "value"},
        );

        expect(myInterface.events.single.metadata?["mutatedBy"], "primary");
        expect(
          secondaryInterface.events.single.metadata?["mutatedBy"],
          "secondary",
        );
      });

      test("unregistering an interface clears registration interceptors",
          () async {
        final TestLoggingInterface secondaryInterface =
            TestLoggingInterface("secondary");

        await Arcane.logger.unregisterInterface(myInterface);
        myInterface = TestLoggingInterface("primary-with-drop");
        await Arcane.logger.registerInterface(
          myInterface,
          interceptors: [
            LogInterceptor((event, {required context}) => null),
          ],
        );

        await Arcane.logger.unregisterInterface(myInterface);
        await Arcane.logger.registerInterface(secondaryInterface);

        Arcane.log(logMessage);

        expect(myInterface.events, isEmpty);
        expect(secondaryInterface.events.single.message, logMessage);
      });

      test("reset clears global interceptors", () async {
        Arcane.logger.registerInterceptor(prefixInterceptor);
        Arcane.logger.reset();
        await Arcane.logger.registerInterface(myInterface);

        Arcane.log(logMessage);

        expect(myInterface.events.single.message, logMessage);
      });
    });
  });
}
