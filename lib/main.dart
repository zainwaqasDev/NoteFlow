import 'package:flutter/material.dart';
import 'package:notes_app/Screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('notesBox');
  await Hive.openBox('settingsBox');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final settingsBox = Hive.box('settingsBox');
  bool isDarkMode = false;
  @override
  void initState() {
    super.initState();
    isDarkMode = settingsBox.get('isDarkMode', defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData(
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                centerTitle: true,
              ),
            ),
      home: SplashScreen(
        onThemeChanged: () {
          setState(() {
            isDarkMode = !isDarkMode;
            settingsBox.put('isDarkMode', isDarkMode);
          });
        },
      ),
    );
  }
}
