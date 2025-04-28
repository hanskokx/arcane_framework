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
  @override
  Widget build(BuildContext context) {
    final bool isSignedIn = Arcane.auth.isSignedIn.value;
    return GridView.extent(
      maxCrossAxisExtent: 300,
      padding: const EdgeInsets.all(16),
      children: [
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                        const Text("Follow system"),
                      ],
                    ),
                  ],
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
                  child: Text(isSignedIn ? "Sign out" : "Sign in"),
                  onPressed: () async {
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
                  },
                ),
                Center(
                  child: Text("Status: ${Arcane.auth.status.name}"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
