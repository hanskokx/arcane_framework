import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:example/config.dart";
import "package:example/interfaces/debug_auth_interface.dart";
import "package:example/interfaces/debug_print_interface.dart";
import "package:example/services/demo_service.dart";
import "package:example/theme/theme.dart";
import "package:flutter/material.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  for (final Feature feature in Feature.values) {
    if (feature.enabledAtStartup) Arcane.features.enableFeature(feature);
  }

  await Future.wait([
    Arcane.logger.registerInterfaces([
      DebugPrint.I,
    ]),
    IdService.I.init(),
  ]);

  Arcane.logger.addPersistentMetadata({
    "session_id": IdService.I.sessionId.value,
  });

  await Arcane.auth.registerInterface(DebugAuthInterface.I);

  Arcane.theme
    ..setDarkTheme(darkTheme)
    ..setLightTheme(lightTheme);

  Arcane.log(
    "Initialization complete.",
    level: Level.info,
    module: "main",
    method: "main",
    metadata: {
      "ready": "true",
    },
  );

  runApp(
    ArcaneApp(
      services: [
        IdService.I,
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Arcane.theme.light,
      darkTheme: Arcane.theme.dark,
      themeMode: Arcane.theme.currentModeOf(context),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Arcane Framework Example"),
        ),
        body: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final StreamSubscription<String> _subscription;
  final List<String> latestLogs = [];
  final List<Color> themeColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.deepPurple,
  ];

  @override
  Widget build(BuildContext context) {
    final bool isSignedIn = Arcane.auth.isSignedIn.value;
    return Column(
      children: [
        Expanded(
          child: GridView.extent(
            maxCrossAxisExtent: 300,
            padding: const EdgeInsets.all(16),
            children: [
              // Theme
              Card(
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
                            value:
                                Arcane.theme.currentThemeMode == ThemeMode.dark,
                            thumbIcon:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Icon(Icons.dark_mode);
                              }
                              return const Icon(Icons.light_mode);
                            }),
                            onChanged: (_) {
                              final ThemeMode oldTheme =
                                  Arcane.theme.currentThemeMode;
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
                                        "newMode":
                                            Arcane.theme.currentThemeMode.name,
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
                                        "newMode":
                                            Arcane.theme.currentThemeMode.name,
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
                              child: ListView.separated(
                                itemCount: themeColors.length,
                                scrollDirection: Axis.horizontal,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 4),
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () {
                                      if (Arcane.theme.currentThemeMode ==
                                          ThemeMode.dark) {
                                        Arcane.theme.setDarkTheme(
                                          ThemeData(
                                            brightness: Brightness.dark,
                                            colorSchemeSeed: themeColors[index],
                                          ),
                                        );
                                      } else if (Arcane
                                              .theme.currentThemeMode ==
                                          ThemeMode.light) {
                                        Arcane.theme.setLightTheme(
                                          ThemeData(
                                            brightness: Brightness.light,
                                            colorSchemeSeed: themeColors[index],
                                          ),
                                        );
                                      }

                                      Arcane.log(
                                        "Setting ${Arcane.theme.currentThemeMode.name} theme color to ${themeColors[index]}",
                                      );
                                    },
                                    child: Container(
                                      color: themeColors[index],
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
                        "The current theme mode is ${context.themeMode.name} and "
                        "is ${Arcane.theme.isFollowingSystemTheme ? "" : "not "}"
                        "following the system theme.",
                      ),
                    ],
                  ),
                ),
              ),

              // Authentication
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
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
                                  await Arcane.auth.logOut(
                                    onLoggedOut: () async {
                                      setState(() {});
                                    },
                                  );
                                } else {
                                  await Arcane.auth.login<Credentials>(
                                    input: (
                                      email: "email",
                                      password: "password",
                                    ),
                                    onLoggedIn: () async {
                                      setState(() {});
                                    },
                                  );
                                }
                              }
                            : null,
                        child: Text(isSignedIn ? "Sign out" : "Sign in"),
                      ),
                      Center(
                        child: Text("Status: ${Arcane.auth.status.name}"),
                      ),
                    ],
                  ),
                ),
              ),

              // Feature flags
              Card(
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
              ),

              // Environment
              Card(
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
                                "previous": ArcaneEnvironment.of(context)
                                    .environment
                                    .name,
                                "current": Environment.debug.name,
                              },
                            );
                          } else {
                            ArcaneEnvironment.of(context).disableDebugMode();
                            Arcane.log(
                              "Environment changed.",
                              metadata: {
                                "previous": ArcaneEnvironment.of(context)
                                    .environment
                                    .name,
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
              ),
            ],
          ),
        ),

        // Logging
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 200,
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
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _subscription = Arcane.logger.logStream.listen((message) {
      setState(() {
        if (Feature.logging.enabled) latestLogs.insert(0, message);
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
