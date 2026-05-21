part of "logging_service.dart";

final class LogInterceptorContext {
  const LogInterceptorContext({
    this.interface,
  });

  final LoggingInterface? interface;
}

class LogInterceptor {
  const LogInterceptor(this._callback);

  final LogEvent? Function(
    LogEvent event, {
    required LogInterceptorContext context,
  }) _callback;

  LogEvent? call(
    LogEvent event, {
    required LogInterceptorContext context,
  }) {
    return _callback(event, context: context);
  }
}
