import 'package:flutter/material.dart';
import 'package:spotshare/utils/constants.dart';
import 'widgets/bottom_navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true; // thème sombre par défaut

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpotShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.green[700],
        scaffoldBackgroundColor: Colors.grey[200],
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: dGreen,
        scaffoldBackgroundColor: dBlack,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: dBlack,
          selectedItemColor: dWhite,
          unselectedItemColor: dGreen,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: BottomNavigationBarExample(toggleTheme: toggleTheme),
    );
  }
}
