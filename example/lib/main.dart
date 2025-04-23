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
      themeMode: Arcane.theme.currentTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Arcane Framework Example"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_system_daydream),
              onPressed: () {
                Arcane.theme.followSystemTheme(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.contrast),
              onPressed: () {
                Arcane.theme.switchTheme();
              },
            ),
          ],
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
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Authentication status: ${Arcane.auth.status.name}",
            ),
            if (isSignedIn)
              ElevatedButton(
                child: const Text("Sign out"),
                onPressed: () async {
                  await Arcane.auth.logOut(
                    onLoggedOut: () async {
                      setState(() {});
                    },
                  );
                },
              ),
            if (!isSignedIn)
              ElevatedButton(
                child: const Text("Sign in"),
                onPressed: () async {
                  await Arcane.auth.login<Credentials>(
                    input: (
                      email: "email",
                      password: "password",
                    ),
                    onLoggedIn: () async {
                      setState(() {});
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
