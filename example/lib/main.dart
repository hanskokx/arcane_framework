import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:example/config.dart";
import "package:example/interfaces/debug_auth_interface.dart";
import "package:example/interfaces/debug_print_interface.dart";
import "package:example/services/favorite_color_service.dart";
import "package:example/theme/theme.dart";
import "package:flutter/material.dart";

Future<void> main() async {
  // If any Feature enum items are `enabledAtStartup`, enable them within Arcane.
  for (final Feature feature in Feature.values) {
    if (feature.enabledAtStartup) Arcane.features.enableFeature(feature);
  }

  // Register the logging interface
  await Arcane.logger.registerInterface(DebugPrint.I);

  // Add some persistent metadata to be used in every future log message
  Arcane.logger.addPersistentMetadata({
    "demo": "This message will be included in all log messages.",
  });

  // Register the authentication interface
  await Arcane.auth.registerInterface(DebugAuthInterface.I);

  // Set the light and dark mode themes using our pre-defined ThemeData classes
  Arcane.theme
    ..setLightTheme(lightTheme)
    ..setDarkTheme(darkTheme);

  // Log a message that the app has been initialized
  Arcane.log(
    "Initialization complete.",
    // Set an appropriate log level
    level: Level.info,
    // The `module` and `method` are _often_ automatically determined, but they can be overridden.
    module: "main",
    method: "main",
    // Skip autodetction of the `module`, `method`, and file/line number where logs originated from.
    skipAutodetection: true,
    // Add some optional metadata to be included in this single log message. This is added to the
    // persistent metadata, if any has been set.
    metadata: {
      "ready": "true",
    },
  );

  runApp(
    // The `ArcaneApp` widget is optional but provides the `ArcaneEnvironmentProvider`,
    // `ArcaneServiceProvider`, and `ArcaneThemeSwitcher` widgets.
    const ArcaneApp(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use the light and dark theme objects registered in Arcane. If either style is
      // updated in Arcane, the changes will reflect here. This allows for on-the-fly
      // customizations without requiring compile-time themes to be pre-defined.
      theme: Arcane.theme.light,
      darkTheme: Arcane.theme.dark,
      // By fetching the current ThemeMode from Arcane, the app will automatically rebuild
      // when the theme is switched, either manually or automatically.
      themeMode: Arcane.theme.currentModeOf(context),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Arcane Framework Example"),
        ),
        body: Column(
          children: [
            Expanded(
              child: GridView.extent(
                maxCrossAxisExtent: 300,
                padding: const EdgeInsets.all(16),
                children: const [
                  ArcaneThemeExample(),
                  ArcaneAuthExample(),
                  ArcaneFeatureFlagsExample(),
                  ArcaneEnvironmentExample(),
                  ArcaneServicesExample(),
                ],
              ),
            ),
            const ArcaneLoggingExample(),
          ],
        ),
      ),
    );
  }
}

// * Logging
// Arcane's logging system gives developers the power to dynamically add and
// remove logging interfaces on-the-fly: try enabling a debug logging interface
// when the app is running in debug mode, adding a third-party logging interface
// when in production, and waiting until after the user has gone through the
// login process to ask them for permission to track. Include useful metadata,
// including persistent metadata, in your log messages. All of these things, and
// more, are possible when using Arcane's logging system.
class ArcaneLoggingExample extends StatefulWidget {
  const ArcaneLoggingExample({
    super.key,
  });

  @override
  State<ArcaneLoggingExample> createState() => _ArcaneLoggingExampleState();
}

class _ArcaneLoggingExampleState extends State<ArcaneLoggingExample> {
  // Set up a subscriber that we can use to listen to logs in realtime.
  // Note: this is completely optional and does _not_ impact whether logs are
  // sent to any registered logging interfaces.
  late final StreamSubscription<String> _logStreamSubscriber;

  // Used to collect the logs from the stream.
  final List<String> latestLogs = [];

  @override
  void initState() {
    super.initState();
    // Listens to the Arcane logger stream of logs and adds them to the latestLogs list.
    _logStreamSubscriber = Arcane.logger.logStream.listen((message) {
      // If [Feature.logging] is disabled, we won't add the logs to the list or trigger
      // a rebuild.
      if (Feature.logging.enabled) {
        setState(() {
          latestLogs.insert(0, message);
        });
      }
    });
  }

  @override
  void dispose() {
    // Don't forget to properly dispose of the subscriber
    _logStreamSubscriber.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Arcane.features.notifier,
      builder: (context, enabledFeatures, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height / 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Logging",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (latestLogs.isEmpty)
                      Text(
                        "Log messages will appear here",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    if (Feature.logging.disabled)
                      Text(
                        "Logging feature is disabled.",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: latestLogs.length,
                        itemBuilder: (context, index) {
                          return Text(latestLogs[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// * Authentication
// Arcane's authentication system provides a simple, standard interface
// for common authentication tasks - including registration and account
// management, logging in and out, etc. Authentication status is reflected
// in realtime within the application as changes happen, so you can focus
// on what's most important.
class ArcaneAuthExample extends StatelessWidget {
  const ArcaneAuthExample({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Arcane.features.notifier,
      builder: (context, enabledFeatures, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder(
              valueListenable: Arcane.auth.isSignedIn,
              builder: (context, isSignedIn, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Authentication",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    ElevatedButton(
                      onPressed: Feature.authentication.enabled
                          ? () async {
                              if (isSignedIn) {
                                await Arcane.auth.logOut();
                              } else {
                                await Arcane.auth.login<Credentials>(
                                  input: (
                                    email: "email",
                                    password: "password",
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(
                        isSignedIn ? "Sign out" : "Sign in",
                      ),
                    ),
                    Center(
                      child: Text("Status: ${Arcane.auth.status.name}"),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// * Theme
// Arcane enables easy, dynamic theme switching. Themes can be switched
// at any time between light mode and dark mode, or set to follow the
// system theme. In addition, themes can be swapped out on-the-fly,
// enabling dynamic customizations and remote theme fetching.
class ArcaneThemeExample extends StatelessWidget {
  const ArcaneThemeExample({
    super.key,
  });

  static final Listenable themeListenable =
      Listenable.merge([Arcane.theme.darkTheme, Arcane.theme.lightTheme]);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Theme",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Column(
              children: [
                Switch(
                  value: Arcane.theme.currentThemeMode == ThemeMode.dark,
                  thumbIcon: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Icon(Icons.dark_mode);
                    }
                    return const Icon(Icons.light_mode);
                  }),
                  onChanged: (_) {
                    final ThemeMode oldTheme = Arcane.theme.currentThemeMode;
                    Arcane.theme.switchTheme();
                    Arcane.log(
                      "Switching theme",
                      metadata: {
                        "followingSystemTheme":
                            "${Arcane.theme.isFollowingSystemTheme}",
                        "newMode": Arcane.theme.currentThemeMode.name,
                        "oldMode": oldTheme.name,
                      },
                    );
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: Arcane.theme.isFollowingSystemTheme,
                      onChanged: (value) {
                        final ThemeMode oldTheme =
                            Arcane.theme.currentThemeMode;
                        if (value == true) {
                          Arcane.theme.followSystemTheme(context);
                          Arcane.log(
                            "Switching theme",
                            metadata: {
                              "followingSystemTheme":
                                  "${Arcane.theme.isFollowingSystemTheme}",
                              "newMode": Arcane.theme.currentThemeMode.name,
                              "oldMode": oldTheme.name,
                            },
                          );
                        } else {
                          Arcane.theme.switchTheme(
                            themeMode: Arcane.theme.systemThemeMode,
                          );
                          Arcane.log(
                            "Switching theme",
                            metadata: {
                              "followingSystemTheme":
                                  "${Arcane.theme.isFollowingSystemTheme}",
                              "newMode": Arcane.theme.currentThemeMode.name,
                              "oldMode": oldTheme.name,
                            },
                          );
                        }
                      },
                    ),
                    const Text("Follow system"),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  const Text("Color"),
                  Expanded(
                    child: StreamBuilder(
                      stream: Arcane.theme.themeDataChanges,
                      builder: (context, themeData) => ListView.separated(
                        itemCount: colors.length,
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              if (context.themeMode == ThemeMode.dark) {
                                Arcane.theme.setDarkTheme(
                                  ThemeData(
                                    brightness: Brightness.dark,
                                    colorSchemeSeed: colors[index],
                                  ),
                                );
                              } else if (context.themeMode == ThemeMode.light) {
                                Arcane.theme.setLightTheme(
                                  ThemeData(
                                    brightness: Brightness.light,
                                    colorSchemeSeed: colors[index],
                                  ),
                                );
                              }

                              Arcane.log(
                                "Setting ${Arcane.theme.currentThemeMode.name} theme color to ${colors[index].name}",
                              );
                            },
                            child: StreamBuilder<ThemeMode>(
                              stream: Arcane.theme.themeModeChanges,
                              builder: (context, themeMode) {
                                return Container(
                                  key:
                                      Key("${colors[index]}-${themeMode.data}"),
                                  decoration: BoxDecoration(
                                    color: colors[index],
                                    border: themeData.data?.colorScheme.primary
                                                .name ==
                                            colors[index].name
                                        ? Border.all(width: 2)
                                        : null,
                                  ),
                                  width: 20,
                                  height: 20,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "The current theme mode is ${Arcane.theme.currentModeOf(context).name} and "
              "is ${Arcane.theme.isFollowingSystemTheme ? "" : "not "}"
              "following the system theme.",
            ),
          ],
        ),
      ),
    );
  }
}

// * Feature flags
// Arcane's feature flag system is extremely simple and flexible to use.
// By registering _any_ enum (or even multiple enums!), features can be
// toggled on and off at any point. The feature flag system even offers
// a notifier, so you can listen to changes as they happen. Fetch your
// remote config and use it to dynamically enable and disable features
// with ease!
class ArcaneFeatureFlagsExample extends StatelessWidget {
  const ArcaneFeatureFlagsExample({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Arcane.features.notifier,
      builder: (context, enabledFeatures, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Feature Flags",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: Feature.values.length,
                    itemBuilder: (context, i) {
                      final Feature feature = Feature.values[i];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(feature.name),
                          Switch(
                            value: feature.enabled,
                            onChanged: (_) {
                              feature.enabled
                                  ? feature.disable()
                                  : feature.enable();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// * Environment
// Quickly and easily toggle between a "normal" and "debug" environment
// within your application. This is particularly useful during development
// when you may want to change the behavior of the application under
// certain conditions.
class ArcaneEnvironmentExample extends StatelessWidget {
  const ArcaneEnvironmentExample({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Environment",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            ElevatedButton(
              onPressed: () {
                final Environment currentEnvironment =
                    ArcaneEnvironment.of(context).environment;
                if (currentEnvironment == Environment.normal) {
                  ArcaneEnvironment.of(context).enableDebugMode();
                  Arcane.log(
                    "Environment changed.",
                    metadata: {
                      "previous":
                          ArcaneEnvironment.of(context).environment.name,
                      "current": Environment.debug.name,
                    },
                  );
                } else {
                  ArcaneEnvironment.of(context).disableDebugMode();
                  Arcane.log(
                    "Environment changed.",
                    metadata: {
                      "previous":
                          ArcaneEnvironment.of(context).environment.name,
                      "current": Environment.normal.name,
                    },
                  );
                }
              },
              child: const Text("Switch environment"),
            ),
            Text(
              "Environment: ${ArcaneEnvironment.of(context).environment.name}",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// * Services
/// Arcane's services system is flexible and minimal, leaving the power
/// and control in developers' hands. This system powers much of Arcane
/// internally, so you know it's reliable.
class ArcaneServicesExample extends StatelessWidget {
  const ArcaneServicesExample({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final FavoriteColorService? service =
        ArcaneServiceProvider.serviceOfType<FavoriteColorService>(context);
    final ValueNotifier<MaterialColor?> notifier =
        service?.notifier ?? ValueNotifier(null);
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, color, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Services",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  color != null ? "Favorite color: ${color.name}" : "",
                ),
                ElevatedButton(
                  onPressed: () {
                    if (service == null) {
                      ArcaneServiceProvider.of(context).addService(
                        FavoriteColorService.I,
                      );

                      Arcane.log(
                        "Service registered.",
                        metadata: {"service": "FavoriteColorService"},
                      );
                    } else {
                      ArcaneServiceProvider.of(context)
                          .removeService<FavoriteColorService>();

                      Arcane.log(
                        "Service removed.",
                        metadata: {"service": "FavoriteColorService"},
                      );
                    }
                  },
                  child: Text(
                    '${service == null ? 'Register' : 'Remove'} service',
                  ),
                ),
                SizedBox(
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      const Text("Color"),
                      Expanded(
                        child: ListView.separated(
                          itemCount: colors.length,
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                if (service == null) {
                                  Arcane.log(
                                    "FavoriteColorService is not registered",
                                  );
                                  return;
                                }

                                service.setMyFavoriteColor(colors[index]);
                                Arcane.log(
                                  "Set a color in FavoriteColorService",
                                  metadata: {
                                    "color": colors[index].name ?? "Unknown",
                                  },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors[index],
                                  border: color?.name == colors[index].name
                                      ? Border.all(width: 2)
                                      : null,
                                ),
                                width: 20,
                                height: 20,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Service is ${service != null ? "" : "not "}registered",
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
