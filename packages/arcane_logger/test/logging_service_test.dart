import "package:arcane_logger/arcane_logger.dart";
import "package:test/test.dart";

class TestLoggingInterface extends LoggingInterface with LoggingInitialization {
  TestLoggingInterface(this.name);

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
  TestPassiveLoggingInterface(this.name);

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

class TestAlternativeLoggingInterface extends LoggingInterface {
  TestAlternativeLoggingInterface(this.name);

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

class TestDerivedLoggingInterface extends TestLoggingInterface {
  TestDerivedLoggingInterface(super.name);
}

class RedactingLogInterceptor implements LogInterceptor {
  const RedactingLogInterceptor();

  @override
  LogEvent? call(LogEvent event, {required LogInterceptorContext context}) {
    final Object? token = event.metadata?["token"];
    if (token == null) return event;

    return event.copyWith(
      metadata: {...?event.metadata, "token": "[redacted]"},
    );
  }
}

class TestLoggerWithLoggerName extends LoggingInterface with LoggerName {
  @override
  String get name => "test-logger";

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

void main() {
  late TestLoggingInterface myInterface;
  late LogInterceptor prefixInterceptor;
  final TestLoggerWithLoggerName loggerWithLoggerName =
      TestLoggerWithLoggerName();

  setUp(() {
    ArcaneLogger.I.reset();
    myInterface = TestLoggingInterface("primary");
    prefixInterceptor = LogInterceptor((event, context) {
      return event.copyWith(message: "[global] ${event.message}");
    });
  });

  group("ArcaneLogger", () {
    group("stream lifecycle", () {
      test("logStream remains usable after listener cancellation", () async {
        String? firstMessage;
        final firstSubscription = ArcaneLogger.I.logStream.listen((message) {
          firstMessage = message;
        });

        ArcaneLogger.I.log("first");
        await Future<void>.delayed(Duration.zero);
        expect(firstMessage, contains("first"));

        await firstSubscription.cancel();

        String? secondMessage;
        final secondSubscription = ArcaneLogger.I.logStream.listen((message) {
          secondMessage = message;
        });

        ArcaneLogger.I.log("second");
        await Future<void>.delayed(Duration.zero);
        expect(secondMessage, contains("second"));

        await secondSubscription.cancel();
      });
    });

    group("interface management", () {
      test("registerInterfaces adds interfaces correctly", () async {
        await ArcaneLogger.I.registerInterface(myInterface);

        expect(ArcaneLogger.I.interfaces, contains(isA<LoggingInterface>()));
      });

      test("registering an interface doesn't initialize it", () async {
        await ArcaneLogger.I.registerInterface(myInterface);

        expect(ArcaneLogger.I.interfaces.first, isA<LoggingInterface>());

        expect(myInterface.initialized, false);
        expect(myInterface.initCallCount, 0);
      });

      test("registering an interface initializes the logger", () async {
        expect(ArcaneLogger.I.initialized, false);

        await ArcaneLogger.I.registerInterface(myInterface);

        expect(ArcaneLogger.I.initialized, true);
      });

      test("interfaces can be initialized through the logger", () async {
        await ArcaneLogger.I.registerInterface(myInterface);

        expect(myInterface.initialized, false);

        await ArcaneLogger.I.initializeInterfaces();

        expect(myInterface.initCallCount, 1);
      });

      test(
        "non-initializable interfaces are skipped by initializeInterfaces",
        () async {
          final TestPassiveLoggingInterface passiveInterface =
              TestPassiveLoggingInterface("passive");

          await ArcaneLogger.I.registerInterfaces([
            myInterface,
            passiveInterface,
          ]);

          await ArcaneLogger.I.initializeInterfaces();

          expect(myInterface.initCallCount, 1);

          ArcaneLogger.I.log("hello");

          expect(myInterface.events.single.message, "hello");
          expect(passiveInterface.events.single.message, "hello");
        },
      );

      test("multiple interfaces can be registered", () async {
        await ArcaneLogger.I.registerInterfaces([
          TestLoggingInterface("first"),
          TestLoggingInterface("second"),
        ]);

        expect(
          ArcaneLogger.I.interfaces,
          contains(isA<TestLoggingInterface>()),
        );
        expect(ArcaneLogger.I.interfaces.length, 2);
      });

      test("global interceptors can be registered at runtime", () async {
        await ArcaneLogger.I.registerInterface(myInterface);

        ArcaneLogger.I.log("before");
        ArcaneLogger.I.interceptors.add(prefixInterceptor);
        ArcaneLogger.I.log("after");

        expect(myInterface.events[0].message, "before");
        expect(myInterface.events[1].message, "[global] after");
      });

      test("interceptor collection add defaults to global", () async {
        await ArcaneLogger.I.registerInterface(myInterface);

        ArcaneLogger.I.log("before");
        ArcaneLogger.I.interceptors.add(prefixInterceptor);
        ArcaneLogger.I.log("after");

        expect(myInterface.events[0].message, "before");
        expect(myInterface.events[1].message, "[global] after");
      });

      test("interface interceptors can be registered at runtime", () async {
        final LogInterceptor dropForPrimary = LogInterceptor((event, context) {
          if ((context.interface as TestLoggingInterface).name == "primary") {
            return null;
          }

          return event;
        });

        await ArcaneLogger.I.registerInterface(myInterface);

        ArcaneLogger.I.log("before");
        ArcaneLogger.I.interceptors.add(
          dropForPrimary,
          matcher: (LoggingInterface interface) =>
              interface is TestLoggingInterface,
        );
        ArcaneLogger.I.log("blocked");

        expect(myInterface.events.map((LogEvent event) => event.message), [
          "before",
        ]);
      });

      test(
        "type-scoped interceptors only apply to matching interfaces",
        () async {
          final TestAlternativeLoggingInterface alternativeInterface =
              TestAlternativeLoggingInterface("alternative");

          await ArcaneLogger.I.registerInterfaces([
            myInterface,
            alternativeInterface,
          ]);

          ArcaneLogger.I.interceptors.add(
            LogInterceptor((event, context) {
              return event.copyWith(message: "[typed] ${event.message}");
            }),
            matcher: (LoggingInterface interface) =>
                interface is TestLoggingInterface,
          );

          ArcaneLogger.I.log("typed");

          expect(myInterface.events.last.message, "[typed] typed");
          expect(alternativeInterface.events.last.message, "typed");
        },
      );

      test(
        "matcher-based type-scoped interceptors can include subtypes",
        () async {
          final TestDerivedLoggingInterface derivedInterface =
              TestDerivedLoggingInterface("derived");
          final TestAlternativeLoggingInterface alternativeInterface =
              TestAlternativeLoggingInterface("alternative");

          await ArcaneLogger.I.registerInterfaces([
            myInterface,
            derivedInterface,
            alternativeInterface,
          ]);

          ArcaneLogger.I.interceptors.add(
            LogInterceptor((event, context) {
              return event.copyWith(message: "[family] ${event.message}");
            }),
            matcher: (LoggingInterface interface) =>
                interface is TestLoggingInterface,
          );

          ArcaneLogger.I.log("typed");

          expect(myInterface.events.last.message, "[family] typed");
          expect(derivedInterface.events.last.message, "[family] typed");
          expect(alternativeInterface.events.last.message, "typed");
        },
      );

      test("registering a type-scoped interceptor before matching interface exists stores it for future registrations", () async {
        final TestLoggingInterface secondary = TestLoggingInterface(
          "secondary",
        );

        ArcaneLogger.I.interceptors.add(
          LogInterceptor((event, context) {
            return event.copyWith(message: "[future] ${event.message}");
          }),
          matcher: (LoggingInterface interface) =>
              interface is TestLoggingInterface,
        );

        await ArcaneLogger.I.registerInterface(secondary);
        ArcaneLogger.I.log("hello");

        expect(secondary.events.single.message, "[future] hello");
      });

      test("registerInterfaces accepts empty interceptor map", () async {
        await ArcaneLogger.I.registerInterfaces([
          myInterface,
        ], interceptors: <LoggingInterface, List<LogInterceptor>>{});

        ArcaneLogger.I.log("hello");
        expect(myInterface.events.single.message, "hello");
      });

      test("unregisterInterfaces removes all listed interfaces", () async {
        final TestLoggingInterface secondary = TestLoggingInterface(
          "secondary",
        );

        await ArcaneLogger.I.registerInterfaces([myInterface, secondary]);
        await ArcaneLogger.I.unregisterInterfaces([myInterface, secondary]);

        expect(ArcaneLogger.I.interfaces, isEmpty);
      });

      test(
        "unregisterAllInterfaces removes all registered interfaces",
        () async {
          final TestLoggingInterface secondary = TestLoggingInterface(
            "secondary",
          );

          await ArcaneLogger.I.registerInterfaces([myInterface, secondary]);
          await ArcaneLogger.I.unregisterAllInterfaces();

          expect(ArcaneLogger.I.interfaces, isEmpty);
        },
      );

      test(
        "initializeInterfaces throws when no interfaces are registered",
        () async {
          await expectLater(
            ArcaneLogger.I.initializeInterfaces(),
            throwsException,
          );
        },
      );
    });

    group("persistent metadata", () {
      test("addPersistentMetadata adds metadata correctly", () {
        ArcaneLogger.I.addPersistentMetadata({"test": "value"});
        expect(ArcaneLogger.I.additionalMetadata["test"], equals("value"));
      });

      test("removePersistentMetadata removes specific key", () {
        ArcaneLogger.I.addPersistentMetadata({"test": "value", "keep": "this"});
        ArcaneLogger.I.removePersistentMetadata("test");
        expect(ArcaneLogger.I.additionalMetadata.containsKey("test"), false);
        expect(ArcaneLogger.I.additionalMetadata["keep"], equals("this"));
      });

      test("clearPersistentMetadata removes all metadata", () {
        ArcaneLogger.I.addPersistentMetadata({
          "test": "value",
          "another": "value",
        });
        ArcaneLogger.I.clearPersistentMetadata();
        expect(ArcaneLogger.I.additionalMetadata.isEmpty, true);
      });

      test("addPersistentMetadata removes an existing key on empty value", () {
        ArcaneLogger.I.addPersistentMetadata({"token": "abc"});
        ArcaneLogger.I.addPersistentMetadata({"token": ""});

        expect(ArcaneLogger.I.additionalMetadata.containsKey("token"), isFalse);
      });

      test("addPersistentMetadata ignores null values for new keys", () {
        ArcaneLogger.I.addPersistentMetadata({"token": null});
        expect(ArcaneLogger.I.additionalMetadata.containsKey("token"), isFalse);
      });
    });

    group("logging messages", () {
      const String logMessage = "Test";

      setUp(() async {
        await ArcaneLogger.I.registerInterface(myInterface);
      });

      test("logging a basic message works", () async {
        ArcaneLogger.I.log(logMessage);

        expect(myInterface.events.single.message, logMessage);
      });

      test("logging at a different level works", () async {
        ArcaneLogger.I.log(logMessage, level: Level.info);

        expect(myInterface.events.last.level, Level.info);

        ArcaneLogger.I.log(logMessage, level: Level.warning);

        expect(myInterface.events.last.level, Level.warning);
      });

      test("logging a stacktrace works", () async {
        final stackTrace = StackTrace.current;
        ArcaneLogger.I.log(logMessage, stackTrace: stackTrace);

        expect(myInterface.events.single.stackTrace, stackTrace);
      });

      test("logging an extra object works", () async {
        const bool extraObject = true;
        ArcaneLogger.I.log(logMessage, extra: extraObject);

        expect(myInterface.events.single.extra, extraObject);
      });

      test("logging metadata works", () async {
        final Map<String, String> metadata = {"test": "value"};
        ArcaneLogger.I.log(logMessage, metadata: metadata);

        expect(myInterface.events.single.metadata?["test"], "value");
        expect(
          myInterface.events.single.metadata?.containsKey("timestamp"),
          true,
        );
      });

      test("explicit method parameter is preserved in metadata", () async {
        ArcaneLogger.I.log(
          logMessage,
          method: "customMethod",
          skipAutodetection: true,
        );

        expect(myInterface.events.single.metadata?["method"], "customMethod");
      });

      test(
        "module and method can be inferred from provided metadata",
        () async {
          ArcaneLogger.I.log(
            logMessage,
            metadata: {"module": "InjectedModule", "method": "InjectedMethod"},
            skipAutodetection: true,
          );

          expect(
            myInterface.events.single.metadata?["module"],
            "InjectedModule",
          );
          expect(
            myInterface.events.single.metadata?["method"],
            "InjectedMethod",
          );
        },
      );

      test("global interceptors run in registration order", () async {
        ArcaneLogger.I.interceptors.addAll([
          LogInterceptor((event, context) {
            expect(context.interface, same(myInterface));
            return event.copyWith(message: "${event.message}:first");
          }),
          LogInterceptor((event, context) {
            expect(context.interface, same(myInterface));
            return event.copyWith(message: "${event.message}:second");
          }),
        ]);

        ArcaneLogger.I.log(logMessage);

        expect(myInterface.events.single.message, "Test:first:second");
      });

      test("global interceptors can drop events for all interfaces", () async {
        await ArcaneLogger.I.registerInterface(myInterface);
        ArcaneLogger.I.interceptors.add(
          LogInterceptor((event, context) => null),
        );

        ArcaneLogger.I.log(logMessage);

        expect(myInterface.events, isEmpty);
      });

      test("interceptor collection remove defaults to global", () async {
        ArcaneLogger.I.interceptors.add(prefixInterceptor);
        ArcaneLogger.I.interceptors.remove(prefixInterceptor);

        ArcaneLogger.I.log(logMessage);

        expect(myInterface.events.single.message, logMessage);
      });

      test("custom interceptor classes can implement LogInterceptor", () async {
        ArcaneLogger.I.interceptors.add(const RedactingLogInterceptor());

        ArcaneLogger.I.log(logMessage, metadata: {"token": "secret-token"});

        expect(myInterface.events.single.metadata?["token"], "[redacted]");
      });

      test("interface interceptors can drop events per destination", () async {
        final TestLoggingInterface secondaryInterface = TestLoggingInterface(
          "secondary",
        );
        final LogInterceptor allowPrimaryOnly = LogInterceptor((
          event,
          context,
        ) {
          final String name = (context.interface as TestLoggingInterface).name;
          return name == "primary" ? event : null;
        });

        ArcaneLogger.I.interceptors.add(
          allowPrimaryOnly,
          matcher: (LoggingInterface interface) =>
              interface is TestLoggingInterface,
        );
        await ArcaneLogger.I.registerInterface(secondaryInterface);

        ArcaneLogger.I.log(logMessage);

        expect(myInterface.events.single.message, logMessage);
        expect(secondaryInterface.events, isEmpty);
      });

      test(
        "interceptor collection remove with matcher removes scoped entries",
        () async {
          final TestLoggingInterface secondaryInterface = TestLoggingInterface(
            "secondary",
          );
          final LogInterceptor scopedInterceptor = LogInterceptor((
            event,
            context,
          ) {
            return event.copyWith(message: "[scoped] ${event.message}");
          });
          bool scopedMatcher(LoggingInterface interface) =>
              interface is TestLoggingInterface;

          ArcaneLogger.I.interceptors.add(
            scopedInterceptor,
            matcher: scopedMatcher,
          );

          await ArcaneLogger.I.registerInterface(secondaryInterface);
          ArcaneLogger.I.interceptors.remove(
            scopedInterceptor,
            matcher: scopedMatcher,
          );

          ArcaneLogger.I.log(logMessage);

          expect(myInterface.events.single.message, logMessage);
          expect(secondaryInterface.events.single.message, logMessage);
        },
      );

      test("interface interceptors receive the current interface", () async {
        final TestLoggingInterface secondaryInterface = TestLoggingInterface(
          "secondary",
        );

        ArcaneLogger.I.interceptors.add(
          LogInterceptor((event, context) {
            final TestLoggingInterface currentInterface =
                context.interface! as TestLoggingInterface;
            return event.copyWith(
              metadata: {...?event.metadata, "target": currentInterface.name},
            );
          }),
          matcher: (LoggingInterface interface) =>
              interface is TestLoggingInterface,
        );
        await ArcaneLogger.I.registerInterface(secondaryInterface);

        ArcaneLogger.I.log(logMessage);

        expect(myInterface.events.single.metadata?["target"], "primary");
        expect(
          secondaryInterface.events.single.metadata?["target"],
          "secondary",
        );
      });

      test(
        "interface interceptors cannot mutate sibling interface events",
        () async {
          final TestLoggingInterface secondaryInterface = TestLoggingInterface(
            "secondary",
          );

          ArcaneLogger.I.interceptors.add(
            LogInterceptor((event, context) {
              event.metadata?["mutatedBy"] =
                  (context.interface as TestLoggingInterface).name;
              return event;
            }),
            matcher: (LoggingInterface interface) =>
                interface is TestLoggingInterface,
          );
          await ArcaneLogger.I.registerInterface(secondaryInterface);

          ArcaneLogger.I.log(logMessage, metadata: {"test": "value"});

          expect(myInterface.events.single.metadata?["mutatedBy"], "primary");
          expect(
            secondaryInterface.events.single.metadata?["mutatedBy"],
            "secondary",
          );
        },
      );

      test(
        "unregistering an interface clears registration interceptors",
        () async {
          final TestLoggingInterface secondaryInterface = TestLoggingInterface(
            "secondary",
          );

          await ArcaneLogger.I.unregisterInterface(myInterface);
          myInterface = TestLoggingInterface("primary-with-drop");
          await ArcaneLogger.I.registerInterface(
            myInterface,
            interceptors: [LogInterceptor((event, context) => null)],
          );

          await ArcaneLogger.I.unregisterInterface(myInterface);
          await ArcaneLogger.I.registerInterface(secondaryInterface);

          ArcaneLogger.I.log(logMessage);

          expect(myInterface.events, isEmpty);
          expect(secondaryInterface.events.single.message, logMessage);
        },
      );

      test("reset clears global interceptors", () async {
        ArcaneLogger.I.interceptors.add(prefixInterceptor);
        ArcaneLogger.I.reset();
        await ArcaneLogger.I.registerInterface(myInterface);

        ArcaneLogger.I.log(logMessage);

        expect(myInterface.events.single.message, logMessage);
      });

      test(
        "global and type-scoped duplicate registrations are additive",
        () async {
          final LogInterceptor duplicateInterceptor = LogInterceptor((
            event,
            context,
          ) {
            final int count = (event.metadata?["count"] as int?) ?? 0;
            return event.copyWith(
              metadata: {...?event.metadata, "count": count + 1},
            );
          });

          ArcaneLogger.I
            ..interceptors.add(duplicateInterceptor)
            ..interceptors.add(
              duplicateInterceptor,
              matcher: (LoggingInterface interface) =>
                  interface is TestLoggingInterface,
            );

          ArcaneLogger.I.log(logMessage, metadata: {"count": 0});

          expect(myInterface.events.single.metadata?["count"], 2);
        },
      );

      test(
        "interceptor collection clear removes global and scoped interceptors",
        () async {
          ArcaneLogger.I.interceptors.add(prefixInterceptor);
          ArcaneLogger.I.interceptors.add(
            LogInterceptor((event, context) {
              return event.copyWith(message: "[scoped] ${event.message}");
            }),
            matcher: (LoggingInterface interface) =>
                interface is TestLoggingInterface,
          );

          ArcaneLogger.I.interceptors.clear();
          ArcaneLogger.I.log(logMessage);

          expect(myInterface.events.single.message, logMessage);
        },
      );
    });
  });

  test("LoggerName mixin exposes name at runtime", () {
    expect(loggerWithLoggerName.name, "test-logger");

    loggerWithLoggerName.log("Test message");
    expect(loggerWithLoggerName.events.length, 1);
    expect(loggerWithLoggerName.events.first.message, "Test message");
  });
}
