import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ucb_app/constants/app_theme.dart';
import 'package:ucb_app/pages/login_screen.dart';
import 'package:ucb_app/pages/dashboard/home_screen.dart';
import 'package:ucb_app/services/hive_service.dart';
import 'package:ucb_app/models/technicien.dart';
import 'package:ucb_app/services/map_service.dart';

void main() async {
  // S'assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();

  // Définir l'orientation en portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCB Techniciens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const InitializationScreen(), // Changé ici
    );
  }
}

// Écran d'initialisation qui charge Hive
class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  bool _isInitializing = true;
  Technicien? _currentTechnicien;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Initialiser Hive
      await HiveService.init();
      
      // 2. Récupérer le technicien connecté (optionnel - pour vérifier)
      final technicien = HiveService.getCurrentTechnicien();

        // Initialiser le service de carte
      await MapService().initialize();
      
      // Petite pause pour que l'écran de chargement soit visible
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _currentTechnicien = technicien;
        _isInitializing = false;
      });
      
    } catch (error) {
      // Gestion d'erreur
      debugPrint('Erreur d\'initialisation: $error');
      // Même en cas d'erreur, on continue vers le login
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const SplashScreen();
    }
    
    // Une fois l'initialisation terminée, décider de la route
    if (_currentTechnicien != null) {
      return HomeScreen(technicien: _currentTechnicien!);
    } else {
      return const LoginScreen();
    }
  }
}

// Écran de chargement (Splash Screen)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // Ou la couleur de votre choix
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de l'application
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.snowing,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            // Texte de chargement
            const Text(
              'UCB Techniciens',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chargement...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            // Indicateur de progression
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}