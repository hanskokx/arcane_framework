import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:example/config.dart";
import "package:example/interfaces/debug_auth_interface.dart";
import "package:example/interfaces/debug_print_interface.dart";
import "package:example/services/favorite_color_service.dart";
import "package:example/theme/theme.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Work around a Flutter web debug assertion where legacy raw key messages
    // can arrive before key data and force an incompatible transit mode.
    SystemChannels.keyEvent.setMessageHandler(
      (_) async => <String, dynamic>{"handled": false},
    );
  }

  final DebugPrint debugPrintInterface = DebugPrint();
  final DebugAuthInterface debugAuthInterface = DebugAuthInterface();

  // If any Feature enum items are `enabledAtStartup`, enable them within Arcane.
  for (final Feature feature in Feature.values) {
    if (feature.enabledAtStartup) Arcane.features.enableFeature(feature);
  }

  // Register the logging interface
  await Arcane.logger.registerInterface(
    debugPrintInterface,
    interceptors: [
      LogInterceptor((event, context) {
        if (context.interface is DebugPrint && Feature.logging.disabled) {
          return null;
        }

        return event;
      }),
    ],
  );

  // Register the authentication interface
  await Arcane.auth.registerInterface(debugAuthInterface);

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
    // The `ArcaneApp` widget is optional but provides Arcane's built-in
    // service, feature flag, environment, and theme integration widgets.
    // It also performs initial platform theme synchronization automatically
    // via ArcaneThemeSwitcher.
    ArcaneApp(
      builder: (context, _) => const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Arcane.theme.light,
      darkTheme: Arcane.theme.dark,
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
  static const String _demoMetadataKey = "demo";
  static const String _demoMetadataValue =
      "This message will be included in all log messages.";

  // Set up a subscriber that we can use to listen to logs in realtime.
  // Note: this is completely optional and does _not_ impact whether logs are
  // sent to any registered logging interfaces.
  late final StreamSubscription<String> _logStreamSubscriber;

  // Used to collect the logs from the stream.
  final List<String> latestLogs = [];
  bool _persistentMetadataEnabled = false;

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
    unawaited(_logStreamSubscriber.cancel());
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
                    Row(
                      spacing: 8,
                      children: [
                        const Text("Include persistent demo metadata"),
                        Switch(
                          value: _persistentMetadataEnabled,
                          onChanged: Feature.logging.disabled
                              ? null
                              : (enabled) {
                                  setState(() {
                                    _persistentMetadataEnabled = enabled;
                                  });

                                  if (enabled) {
                                    Arcane.logger.addPersistentMetadata({
                                      _demoMetadataKey: _demoMetadataValue,
                                    });
                                  } else {
                                    Arcane.logger.removePersistentMetadata(
                                      _demoMetadataKey,
                                    );
                                  }
                                },
                        ),
                      ],
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Checkbox(
                          value: Arcane.theme.isFollowingSystemTheme,
                          onChanged: (value) {
                            if (value == true) {
                              Arcane.theme.followSystemTheme(context);
                            } else {
                              Arcane.theme.switchTheme(
                                themeMode: Arcane.theme.systemTheme,
                              );
                            }
                          },
                        ),
                        const Text("Use system theme"),
                      ],
                    ),
                    Switch(
                      value: Arcane.theme.currentTheme == ThemeMode.dark,
                      thumbIcon: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Icon(Icons.dark_mode);
                        }
                        return const Icon(Icons.light_mode);
                      }),
                      onChanged: (_) {
                        Arcane.theme.switchTheme();
                      },
                    ),
                    Text(
                      "The current theme mode is ${context.themeMode.name} and\n"
                      "is ${Arcane.theme.isFollowingSystemTheme ? "" : "not "}"
                      "following the system theme.",
                    ),
                  ],
                ),
              ),
            ),
            Text(
              "Theme",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Column(
              children: [
                Switch(
                  value: context.isDarkMode,
                  thumbIcon: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Icon(Icons.dark_mode);
                    }
                    return const Icon(Icons.light_mode);
                  }),
                  onChanged: (_) {
                    // Always disable system mode and flip to the opposite of the effective mode
                    Arcane.theme.switchTheme(
                      themeMode:
                          context.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                    );
                    Arcane.log(
                      "Switching theme",
                      metadata: {
                        "followingSystemTheme":
                            "${Arcane.theme.isFollowingSystemTheme}",
                        "newMode": Arcane.theme.currentThemeMode.name,
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
                        if (value == true) {
                          Arcane.theme.followSystemTheme(context);
                        } else {
                          // When unchecking, set mode to the effective mode (not system)
                          final ThemeMode effective =
                              Theme.of(context).brightness == Brightness.dark
                                  ? ThemeMode.dark
                                  : ThemeMode.light;
                          Arcane.theme.switchTheme(themeMode: effective);
                        }
                        Arcane.log(
                          "Switching theme",
                          metadata: {
                            "followingSystemTheme":
                                "${Arcane.theme.isFollowingSystemTheme}",
                            "newMode": Arcane.theme.currentThemeMode.name,
                          },
                        );
                      },
                    ),
                    const Text("Follow system"),
                  ],
                ),
              ],
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
// a notifier, stream, and app-level scope so you can react to changes as
// they happen. Fetch your remote config and use it to dynamically enable
// and disable features with ease!
class ArcaneFeatureFlagsExample extends StatelessWidget {
  const ArcaneFeatureFlagsExample({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ArcaneFeatureFlagProvider flags = context.featureFlags;

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
                        value: flags.isEnabled(feature),
                        onChanged: (_) {
                          flags.isEnabled(feature)
                              ? flags.disableFeature(feature)
                              : flags.enableFeature(feature);
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
  }
}

// * Environment
// Quickly and easily toggle between a "normal" and "debug" environment
// within your application. This is particularly useful during development
// when you may want to change the behavior of the application under
// certain conditions.
class ArcaneEnvironmentExample extends StatelessWidget {
  static const Environment stagingEnvironment = Environment("staging");

  const ArcaneEnvironmentExample({
    super.key,
  });

  Environment _nextEnvironment(Environment current) {
    if (current == Environment.normal) return Environment.debug;
    if (current == Environment.debug) return stagingEnvironment;
    return Environment.normal;
  }

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
                final ArcaneEnvironmentService environment = Arcane.environment;
                final Environment previousEnvironment = environment.current;
                final Environment nextEnvironment = _nextEnvironment(
                  previousEnvironment,
                );

                environment.setEnvironment(nextEnvironment);

                Arcane.log(
                  "Environment changed.",
                  metadata: {
                    "previous": previousEnvironment.name,
                    "current": nextEnvironment.name,
                  },
                );
              },
              child: const Text("Cycle environment"),
            ),
            ValueListenableBuilder<Environment>(
              valueListenable: Arcane.environment.notifier,
              builder: (context, environment, _) {
                return Text(
                  "Environment: ${environment.name}",
                  textAlign: TextAlign.center,
                );
              },
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
    final ArcaneServiceProvider serviceProvider = ArcaneServiceProvider.of(
      context,
    );

    return ValueListenableBuilder<List<ArcaneService>>(
      valueListenable: serviceProvider.notifier!,
      builder: (context, _, __) {
        final FavoriteColorService? service =
            ArcaneServiceProvider.serviceOfType<FavoriteColorService>(context);

        Widget buildCard(MaterialColor? color) {
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
                        final FavoriteColorService nextService =
                            FavoriteColorService()
                              ..syncFromCurrentTheme(colors);

                        serviceProvider.addService(
                          nextService,
                        );

                        Arcane.log(
                          "Service registered.",
                          metadata: {"service": "FavoriteColorService"},
                        );
                      } else {
                        serviceProvider.removeService<FavoriteColorService>();

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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 4),
                            itemBuilder: (context, index) {
                              return Opacity(
                                opacity: service == null ? 0.4 : 1,
                                child: InkWell(
                                  onTap: service == null
                                      ? null
                                      : () {
                                          service.setMyFavoriteColor(
                                            colors[index],
                                          );
                                          Arcane.log(
                                            "Set a color in FavoriteColorService",
                                            metadata: {
                                              "color": colors[index].name ??
                                                  "Unknown",
                                            },
                                          );
                                        },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors[index],
                                      border: color == colors[index]
                                          ? Border.all(width: 2)
                                          : null,
                                    ),
                                    width: 20,
                                    height: 20,
                                  ),
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
        }

        if (service == null) return buildCard(null);

        return ValueListenableBuilder<MaterialColor?>(
          valueListenable: service.notifier,
          builder: (context, color, _) => buildCard(color),
        );
      },
    );
  }
}
