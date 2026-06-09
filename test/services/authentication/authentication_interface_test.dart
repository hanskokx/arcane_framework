import "package:arcane_framework/src/services/authentication/authentication_service.dart";
import "package:flutter_test/flutter_test.dart";
import "package:result_monad/result_monad.dart";

class MockAuth implements ArcaneAuthInterface {
  @override
  Future<Result<void, String>> login<T>({
    T? input,
    Future<void> Function()? onLoggedIn,
  }) async {
    if (onLoggedIn != null) await onLoggedIn();
    return const Result.ok(null);
  }

  @override
  Future<bool> get isSignedIn => Future.value(true);

  @override
  Future<String?>? get accessToken => Future.value("token");

  @override
  Future<String?>? get refreshToken => Future.value("refresh");

  @override
  Future<void> init() async {}

  @override
  Future<Result<void, String>> logout({
    Future<void> Function()? onLoggedOut,
  }) async {
    if (onLoggedOut != null) await onLoggedOut();
    return const Result.ok(null);
  }
}

class MinimalAuth extends ArcaneAuthInterface {
  @override
  Future<bool> get isSignedIn => Future.value(false);

  @override
  Future<String?>? get accessToken => Future.value(null);

  @override
  Future<String?>? get refreshToken => Future.value(null);

  @override
  Future<Result<void, String>> login<T>({
    T? input,
    Future<void> Function()? onLoggedIn,
  }) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<void, String>> logout({
    Future<void> Function()? onLoggedOut,
  }) async {
    return const Result.ok(null);
  }
}

void main() {
  test("MockAuth fulfills ArcaneAuthInterface contract", () async {
    final auth = MockAuth();
    expect(await auth.isSignedIn, isTrue);
    expect(await auth.accessToken, "token");
    expect(await auth.refreshToken, "refresh");
    var called = false;
    await auth.logout(
      onLoggedOut: () async {
        called = true;
      },
    );
    expect(called, isTrue);
  });

  test("default init implementation completes", () async {
    final auth = MinimalAuth();
    await auth.init();
  });
}
