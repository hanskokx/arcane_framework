# Arcane Framework Example

This example app demonstrates the major Arcane services together in a single
Flutter UI:

- Logging with interceptors and realtime log stream subscriptions
- Authentication with sign-in and sign-out actions
- Feature flag toggling with live UI updates
- Environment switching
- Theme switching and system theme following
- Custom app services via `ArcaneService`

## Run the example

From the repository root:

```shell
cd example
flutter pub get
flutter run
```

## Where to look

- `example/lib/main.dart`: app bootstrap, Arcane service setup, and all feature demos
- `example/lib/interfaces/debug_print_interface.dart`: sample logging interface
- `example/lib/interfaces/debug_auth_interface.dart`: sample auth provider
- `example/lib/services/favorite_color_service.dart`: custom Arcane service example

## Stream subscription lifecycle

The example intentionally uses stream subscriptions in widgets and cancels them
in `dispose` to model lifecycle-safe usage.

Key patterns shown in the app include:

- Subscribing to `Arcane.logger.logStream` in `initState`
- Canceling subscriptions in `dispose`
- Rebuilding UI from stream and notifier changes
- Rebuilding UI from `ArcaneFeatureFlagProvider.of(context)` dependencies
- Using `context.featureFlags` convenience access in widgets

`ArcaneApp` composes built-in providers/switchers for Arcane services,
feature flags, environment, and theme updates, and this example demonstrates
all of them working together.

Use this app as a reference for combining Arcane streams and `ValueNotifier`
listeners in the same codebase.
