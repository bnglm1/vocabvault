import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'models/theme_provider.dart';
import 'services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();
  
  try {
    await TranslationService.loadLanguage();
  } catch (e) {
    print('Dil yükleme hatası: $e');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _currentLanguage = 'tr'; // Varsayılan değer
  
  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
    // Periyodik olarak dil değişimini kontrol et
    _startLanguageCheck();
  }
  
  // Mevcut dili yükle
  Future<void> _loadCurrentLanguage() async {
    _currentLanguage = TranslationService.getCurrentLanguage();
    setState(() {}); // UI'yi güncelle
  }
  
  // Periyodik dil kontrolü
  void _startLanguageCheck() {
    Future.delayed(Duration(seconds: 2), () {
      if (!mounted) return;
      
      String newLang = TranslationService.getCurrentLanguage();
      
      if (_currentLanguage != newLang) {
        setState(() {
          _currentLanguage = newLang;
        });
      }
      
      _startLanguageCheck(); // Tekrar kontrol et
    });
  }

  @override    
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'VocabVault',
      themeMode: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.amber,
        brightness: Brightness.dark,
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        // If we have user data, they're signed in
        if (snapshot.hasData) {
          return HomeScreen();
        }
        // Otherwise show sign in screen
        return SignInScreen();
      },
    );
  }
}

