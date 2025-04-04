import "package:arcane_framework/arcane_framework.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";

import "logging_service_test.mocks.dart";

class MyOtherLoggingInterface extends Mock implements MockLoggingInterface {}

@GenerateNiceMocks([
  MockSpec<LoggingInterface>(
    onMissingStub: OnMissingStub.returnDefault,
  ),
])
void main() {
  final LoggingInterface myInterface = MockLoggingInterface();

  setUp(() {
    Arcane.logger.reset();
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
        verifyNever(myInterface.init());
      });

      test("registering an interface initializes the logger", () async {
        expect(Arcane.logger.initialized, false);

        await Arcane.logger.registerInterface(myInterface);

        expect(Arcane.logger.initialized, true);
      });

      test("interfaces can be initialized through the logger", () async {
        await Arcane.logger.registerInterface(myInterface);

        expect(Arcane.logger.interfaces.first.initialized, false);

        await Arcane.logger.initializeInterfaces();

        verify(Arcane.logger.interfaces.first.init()).called(1);
      });

      test("multiple interfaces can be registered", () async {
        await Arcane.logger.registerInterfaces([
          MockLoggingInterface(),
          MyOtherLoggingInterface(),
        ]);

        expect(
          Arcane.logger.interfaces,
          contains(isA<MockLoggingInterface>()),
        );
        expect(
          Arcane.logger.interfaces,
          contains(isA<MyOtherLoggingInterface>()),
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

        verify(
          myInterface.log(
            logMessage,
            metadata: anyNamed("metadata"),
            level: anyNamed("level"),
            stackTrace: anyNamed("stackTrace"),
            extra: anyNamed("extra"),
          ),
        ).called(1);
      });

      test("logging at a different level works", () async {
        Arcane.log(
          logMessage,
          level: Level.info,
        );

        verify(
          myInterface.log(
            logMessage,
            metadata: anyNamed("metadata"),
            level: Level.info,
            stackTrace: anyNamed("stackTrace"),
            extra: anyNamed("extra"),
          ),
        ).called(1);

        Arcane.log(
          logMessage,
          level: Level.warning,
        );

        verify(
          myInterface.log(
            logMessage,
            metadata: anyNamed("metadata"),
            level: Level.warning,
            stackTrace: anyNamed("stackTrace"),
            extra: anyNamed("extra"),
          ),
        ).called(1);
      });

      test("logging a stacktrace works", () async {
        final stackTrace = StackTrace.current;
        Arcane.log(logMessage, stackTrace: stackTrace);

        verify(
          myInterface.log(
            logMessage,
            metadata: anyNamed("metadata"),
            level: anyNamed("level"),
            stackTrace: stackTrace,
            extra: anyNamed("extra"),
          ),
        ).called(1);
      });

      test("logging an extra object works", () async {
        const bool extraObject = true;
        Arcane.log(
          logMessage,
          extra: extraObject,
        );

        verify(
          myInterface.log(
            logMessage,
            metadata: anyNamed("metadata"),
            level: anyNamed("level"),
            stackTrace: anyNamed("stackTrace"),
            extra: extraObject,
          ),
        ).called(1);
      });

      test("logging metadata works", () async {
        final Map<String, String> metadata = {"test": "value"};
        Arcane.log(
          logMessage,
          metadata: metadata,
        );

        verify(
          myInterface.log(
            logMessage,
            metadata: metadata,
            level: anyNamed("level"),
            stackTrace: anyNamed("stackTrace"),
            extra: anyNamed("extra"),
          ),
        ).called(1);
      });
    });
  });
}
