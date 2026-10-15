import "package:arcane_service/arcane_service.dart";
import "package:test/test.dart";

class _AlphaService extends ArcaneService {}

class _BetaService extends ArcaneService {}

void main() {
  group("ArcaneChangeNotifier", () {
    test("tracks listeners and notifies them", () {
      final _Recorder recorder = _Recorder()..addListener(() {});
      expect(recorder.hasListeners, isTrue);

      int calls = 0;
      void listener() => calls++;
      recorder.addListener(listener);

      recorder.ping();
      expect(calls, 1);

      recorder.removeListener(listener);
      recorder.ping();
      expect(calls, 1);
    });

    test("does not notify after dispose", () {
      final _Recorder recorder = _Recorder();
      int calls = 0;
      recorder.addListener(() => calls++);

      recorder.dispose();
      expect(recorder.isDisposed, isTrue);
      recorder.ping();
      expect(calls, 0);
    });

    test(
      "allows listeners to mutate the listener list during notification",
      () {
        final _Recorder recorder = _Recorder();
        void selfRemoving() => recorder.removeListener(selfRemoving);
        recorder.addListener(selfRemoving);

        expect(() => recorder.ping(), returnsNormally);
        expect(recorder.hasListeners, isFalse);
      },
    );
  });

  group("ArcaneValueNotifier", () {
    test("notifies only when the value changes", () {
      final ArcaneValueNotifier<int> notifier = ArcaneValueNotifier<int>(1);
      int calls = 0;
      notifier.addListener(() => calls++);

      notifier.value = 1;
      expect(calls, 0);

      notifier.value = 2;
      expect(calls, 1);
      expect(notifier.value, 2);
    });

    test("exposes value through ArcaneValueListenable", () {
      final ArcaneValueListenable<int> listenable = ArcaneValueNotifier<int>(7);
      expect(listenable.value, 7);
    });
  });

  group("ArcaneServices", () {
    tearDown(() => ArcaneServices.I.clear());

    test("is a singleton", () {
      expect(ArcaneServices.I, same(ArcaneServices.I));
    });

    test("starts empty", () {
      ArcaneServices.I.clear();
      expect(ArcaneServices.I.isEmpty, isTrue);
      expect(ArcaneServices.I.services, isEmpty);
    });

    test("register replaces the registry with an unmodifiable snapshot", () {
      final _AlphaService alpha = _AlphaService();
      ArcaneServices.I.register(<ArcaneService>[alpha]);

      final List<ArcaneService> snapshot = ArcaneServices.I.services;
      expect(snapshot, <ArcaneService>[alpha]);
      expect(() => snapshot.add(_BetaService()), throwsUnsupportedError);
    });

    test("add appends new types and replaces existing ones", () {
      final _AlphaService first = _AlphaService();
      final _AlphaService second = _AlphaService();
      final _BetaService beta = _BetaService();

      ArcaneServices.I
        ..add(first)
        ..add(beta)
        ..add(second);

      expect(ArcaneServices.I.services, <ArcaneService>[second, beta]);
      expect(ArcaneServices.I.ofType<_AlphaService>(), same(second));
    });

    test("remove drops every service of the given type", () {
      ArcaneServices.I.register(<ArcaneService>[
        _AlphaService(),
        _BetaService(),
      ]);

      expect(ArcaneServices.I.remove<_AlphaService>(), isTrue);
      expect(ArcaneServices.I.ofType<_AlphaService>(), isNull);
      expect(ArcaneServices.I.ofType<_BetaService>(), isNotNull);

      expect(ArcaneServices.I.remove<_AlphaService>(), isFalse);
    });

    test("ofType and requiredOfType resolve registered services", () {
      final _BetaService beta = _BetaService();
      ArcaneServices.I.register(<ArcaneService>[beta]);

      expect(ArcaneServices.I.ofType<_BetaService>(), same(beta));
      expect(ArcaneServices.I.requiredOfType<_BetaService>(), same(beta));
      expect(ArcaneServices.I.ofType<_AlphaService>(), isNull);
      expect(
        () => ArcaneServices.I.requiredOfType<_AlphaService>(),
        throwsA(isA<AssertionError>()),
      );
    });

    test("notifies registry listeners when services change", () {
      int calls = 0;
      void listener() => calls++;
      ArcaneServices.I.registry.addListener(listener);

      ArcaneServices.I.register(<ArcaneService>[_AlphaService()]);
      expect(calls, 1);

      ArcaneServices.I.add(_BetaService());
      expect(calls, 2);

      ArcaneServices.I
        ..clear()
        ..clear();
      expect(calls, 3);

      ArcaneServices.I.registry.removeListener(listener);
    });
  });
}

class _Recorder with ArcaneChangeNotifier {
  void ping() => notifyListeners();
}
