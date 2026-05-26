part of "logging_service.dart";

final class LoggingInterceptorsService {
  LoggingInterceptorsService._internal();

  static final LoggingInterceptorsService _instance =
      LoggingInterceptorsService._internal();

  static LoggingInterceptorsService get I => _instance;

  final List<LogInterceptor> _globalInterceptors = [];
  final List<_InterfaceScopedInterceptorRegistration>
      _interfaceScopedInterceptorRegistrations = [];
  final List<_TypeScopedInterceptorRegistration>
      _typeScopedInterceptorRegistrations = [];

  /// Registers an interceptor.
  ///
  /// If [matcher] is omitted, the interceptor is registered globally.
  void add(
    LogInterceptor interceptor, {
    bool Function(LoggingInterface interface)? matcher,
  }) {
    if (matcher == null) {
      _globalInterceptors.add(interceptor);
      return;
    }

    _typeScopedInterceptorRegistrations.add(
      _TypeScopedInterceptorRegistration(
        interceptor: interceptor,
        matcher: matcher,
      ),
    );
  }

  /// Registers multiple interceptors.
  void addAll(
    Iterable<LogInterceptor> interceptors, {
    bool Function(LoggingInterface interface)? matcher,
  }) {
    for (final LogInterceptor interceptor in interceptors) {
      add(interceptor, matcher: matcher);
    }
  }

  /// Removes interceptor registrations.
  ///
  /// If [matcher] is omitted, global registrations are removed.
  /// If [matcher] is provided, scoped registrations with the same matcher
  /// identity are removed.
  void remove(
    LogInterceptor interceptor, {
    bool Function(LoggingInterface interface)? matcher,
  }) {
    if (matcher == null) {
      _globalInterceptors.removeWhere(
        (LogInterceptor current) => identical(current, interceptor),
      );
      return;
    }

    _typeScopedInterceptorRegistrations.removeWhere(
      (_TypeScopedInterceptorRegistration registration) =>
          identical(registration.interceptor, interceptor) &&
          identical(registration.matcher, matcher),
    );
  }

  /// Clears all globally and scoped interceptor registrations.
  void clear() {
    _globalInterceptors.clear();
    _interfaceScopedInterceptorRegistrations.clear();
    _typeScopedInterceptorRegistrations.clear();
  }

  /// Clears global interceptor registrations.
  void clearGlobal() => _globalInterceptors.clear();

  void registerForInterface(
    LoggingInterface interface,
    Iterable<LogInterceptor> interceptors,
  ) {
    for (final LogInterceptor interceptor in interceptors) {
      _interfaceScopedInterceptorRegistrations.add(
        _InterfaceScopedInterceptorRegistration(
          interface: interface,
          interceptor: interceptor,
        ),
      );
    }
  }

  void unregisterInterface(LoggingInterface interface) {
    _interfaceScopedInterceptorRegistrations.removeWhere(
      (_InterfaceScopedInterceptorRegistration registration) =>
          identical(registration.interface, interface),
    );
  }

  List<LogInterceptor> resolveForInterface(
    LoggingInterface interface,
  ) {
    return [
      ..._globalInterceptors,
      for (final _InterfaceScopedInterceptorRegistration registration
          in _interfaceScopedInterceptorRegistrations)
        if (identical(registration.interface, interface))
          registration.interceptor,
      for (final _TypeScopedInterceptorRegistration registration
          in _typeScopedInterceptorRegistrations)
        if (registration.matches(interface)) registration.interceptor,
    ];
  }
}

final class _LoggingInterfaceRegistration {
  _LoggingInterfaceRegistration({
    required this.interface,
  });

  final LoggingInterface interface;
}

final class _InterfaceScopedInterceptorRegistration {
  const _InterfaceScopedInterceptorRegistration({
    required this.interface,
    required this.interceptor,
  });

  final LoggingInterface interface;
  final LogInterceptor interceptor;
}

final class _TypeScopedInterceptorRegistration {
  _TypeScopedInterceptorRegistration({
    required this.interceptor,
    required bool Function(LoggingInterface interface) matcher,
  }) : _matcher = matcher;

  final LogInterceptor interceptor;
  final bool Function(LoggingInterface interface) _matcher;

  bool Function(LoggingInterface interface) get matcher => _matcher;

  bool matches(LoggingInterface interface) => _matcher(interface);
}
