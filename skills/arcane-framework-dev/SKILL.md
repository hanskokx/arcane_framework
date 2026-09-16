---
name: arcane-framework-dev
description: Writing idiomatic Dart/Flutter apps with arcane_framework, including bootstrapping, services, logging, authentication, theming, feature flags, and the environment API.
---

# Building apps with arcane_framework

Use this skill whenever you write or modify application code that uses
[arcane_framework].

## Scope

| Area | Guidance |
| --- | --- |
| App bootstrap | `main()` wires `Arcane` before `runApp`, then mounts `ArcaneApp`. |
| Services | Register your services with `ArcaneServiceProvider`; feature-owned services live under the feature. |
| State | `Arcane.features`, `Arcane.auth`, `Arcane.theme`, `Arcane.environment` are all listenables. |
| Logging | `Arcane.log` everywhere; never `print`. |
| Verification | `dart format`, `dart analyze`, `dart test`; keep the 90% coverage gate green. |

## Quick start

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  for (final Feature feature in Feature.values) {
    if (feature.enabledAtStartup) Arcane.features.enableFeature(feature);
  }

  await Arcane.logger.registerInterface(MyLogInterface());
  await Arcane.auth.registerInterface(MyAuthInterface());
  Arcane.theme
    ..setLightTheme(lightTheme)
    ..setDarkTheme(darkTheme);

  Arcane.log("Initialization complete.", level: Level.info);

  runApp(ArcaneApp(builder: (context, _) => const MainApp()));
}
```

`Feature` is **your own enum**; give each value an `enabledAtStartup` flag and
enable them before anything else runs.

## The `Arcane.*` API

- `Arcane.logger` / `Arcane.log(...)` — logging. Register/remove logging
  interfaces on the fly, add interceptors (`LogInterceptor(fn)` returning
  `null` to drop), stream live logs via `Arcane.logger.logStream`, and attach
  persistent metadata with `addPersistentMetadata`/`removePersistentMetadata`.
  `Arcane.log` takes `level:`, `module:`, `method:`, `skipAutodetection:`,
  and `metadata:`.
- `Arcane.auth` — authentication. `registerInterface`, `login<Credentials>(
  input:)`, `logOut()`, `status`, and the `isSignedIn` value notifier.
- `Arcane.theme` — theming. `setLightTheme`, `setDarkTheme`, `light`,
  `dark`, `currentModeOf(context)`, `switchTheme(themeMode:)`,
  `followSystemTheme(context)`, `isFollowingSystemTheme`.
- `Arcane.features` — feature flags. `enableFeature`, `disableFeature`,
  `isEnabled`, `notifier`. Read with `context.featureFlags.isEnabled(feature)`.
- `Arcane.environment` — environments. `current`, `setEnvironment`, `notifier`;
  `Environment.normal` and `Environment.debug` are built in.
- `ArcaneServiceProvider.of(context)` / `.serviceOfType<T>(context)` — your
  feature services. Add with `addService`, remove with `removeService<T>`.
- `ArcaneApp(builder: (context, _) => ...)` — optional top-level widget that
  wires service, feature flag, environment, and theme integration and performs
  initial platform theme sync.

For UI, hook the notifiers with `ValueListenableBuilder` (features, auth,
environment, services) rather than polling.

`MaterialApp(theme: Arcane.theme.light, darkTheme: Arcane.theme.dark,
themeMode: Arcane.theme.currentModeOf(context))` is the idiomatic wiring.

## Architecture conventions

- Feature-based layout under `lib/features/<feature>/`, with `lib/common/` for
  shared code (router, theme, services, widgets) and `lib/common/injector.dart`
  for dependency injection.
- Navigation is a single `GoRouter` `AppRouter` with an `AppRoute` enum and
  `redirects.dart` guards.
- Blocs take their repositories via constructors and are provided at the
  screen level; app-wide singletons go through `arcane_framework` injection.
- Theme lives in `lib/common/theme/` (`AppTheme.init()` + `theme_parts/`).

## Style rules

Follow the Dart/Flutter style guide in AGENTS.md strictly: double quotes,
trailing commas, `///` docs, `<80` char lines, `final`, `const` first, no
uncalled getters, relative imports within the package, `package:` imports from
tests, avoid `print`, use `// TODO(owner): message`.

## Verification workflow (always run)

```sh
dart format lib test bin
dart analyze
dart test
bash tool/check_coverage.sh   # 90% line gate, scoped to lib/src + lib/arcane_framework.dart
```

Fix every analyzer diagnostic; the analyzer treats `missing_required_param`
and `missing_return` as errors and has `strict-casts` enabled. Generated files
(`*.g.dart`, `*.freezed.dart`, platform dirs) are excluded from analysis.