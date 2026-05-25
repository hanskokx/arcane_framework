import "package:arcane_framework/src/services/authentication/authentication_service.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("SignUpStep", () {
    test("values are correct", () {
      expect(SignUpStep.confirmSignUp.index, 0);
      expect(SignUpStep.done.index, 1);
    });
  });

  group("AuthenticationStatus", () {
    test("isAuthenticated returns true only for authenticated", () {
      expect(AuthenticationStatus.authenticated.isAuthenticated, isTrue);
      expect(AuthenticationStatus.unauthenticated.isAuthenticated, isFalse);
    });
    test("isUnauthenticated returns true only for unauthenticated", () {
      expect(AuthenticationStatus.authenticated.isUnauthenticated, isFalse);
      expect(AuthenticationStatus.unauthenticated.isUnauthenticated, isTrue);
    });
  });
}
