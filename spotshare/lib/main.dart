import 'package:flutter/material.dart';
import 'package:spotshare/services/storage_service.dart';
import 'package:spotshare/utils/constants.dart';
import 'widgets/bottom_navigation.dart';
import 'pages/Account/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // État de connexion : null = chargement, false = pas connecté, true = connecté
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    bool loggedIn = await StorageService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pendant le chargement du token, on affiche un écran de chargement
    if (_isLoggedIn == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: dGreen)),
        ),
      );
    }

    return MaterialApp(
      title: 'SpotShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.green[700],
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: dGreen,
        scaffoldBackgroundColor: dBlack,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: dBlack,
          selectedItemColor: dWhite,
          unselectedItemColor: Colors.grey,
        ),
      ),
      themeMode: ThemeMode.dark, // Force le dark mode pour le style Instagram
      // Si connecté -> BottomNav (Appli), Sinon -> Login
      home: _isLoggedIn!
          ? const BottomNavigationBarExample()
          : const LoginPage(),
    );
  }
}
