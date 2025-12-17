import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ucb_app/pages/dashboard/home_screen.dart';
import 'package:ucb_app/services/hive_service.dart';
import 'package:ucb_app/models/technicien.dart';
import 'package:ucb_app/constants/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final _motDePasseController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec les identifiants de test depuis HiveService
    _prefillCredentials();
  }

  void _prefillCredentials() {
    // Pré-remplir avec le premier technicien de test
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _matriculeController.text.isEmpty) {
        final techniciens = HiveService.getAllTechniciens();
        if (techniciens.isNotEmpty) {
          setState(() {
            // Utiliser le matricule du premier technicien
            _matriculeController.text = techniciens.first.matricule; // TECH-2024-001
            _motDePasseController.text = techniciens.first.motDePasse; // password123
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Réinitialiser le message d'erreur
    setState(() {
      _errorMessage = null;
    });

    // Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final matricule = _matriculeController.text.trim();
    final motDePasse = _motDePasseController.text.trim();

    print('🔍 Tentative de connexion avec matricule: $matricule');

    try {
      // 1️⃣ Vérifier si le technicien existe localement
      final technicien = HiveService.getTechnicienByMatricule(matricule);

      if (technicien != null) {
        print('✅ Technicien trouvé: ${technicien.prenom} ${technicien.nom}');
        print('🔑 Mot de passe stocké: ${technicien.motDePasse}');
        
        // Vérifier le mot de passe
        if (technicien.motDePasse == motDePasse) {
          if (technicien.actif) {
            // Connexion réussie
            print('🔐 Connexion réussie pour ${technicien.matricule}');
            await HiveService.saveCurrentTechnicien(technicien);
            _navigateToHome(technicien);
          } else {
            setState(() {
              _errorMessage = 'Compte désactivé. Contactez l\'administration.';
              _isLoading = false;
            });
          }
        } else {
          print('❌ Mot de passe incorrect');
          setState(() {
            _errorMessage = 'Matricule ou mot de passe incorrect';
            _isLoading = false;
          });
        }
      } else {
        print('❌ Aucun technicien trouvé avec matricule: $matricule');
        
        // Debug: afficher tous les techniciens disponibles
        final allTechs = HiveService.getAllTechniciens();
        print('📋 Techniciens disponibles:');
        for (var tech in allTechs) {
          print('  - ${tech.matricule} (${tech.prenom} ${tech.nom})');
        }
        
        setState(() {
          _errorMessage = 'Technicien non trouvé. Vérifiez votre matricule.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      setState(() {
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToHome(Technicien technicien) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen(technicien: technicien)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    "assets/icon/logo.jpeg",
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Icon(
                          Icons.snowing,
                          color: Colors.white,
                          size: 60,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  Text(
                    'UCB Techniciens',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sous-titre
                  Text(
                    'Connectez-vous pour accéder à votre espace',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Champ Matricule
                  TextFormField(
                    controller: _matriculeController,
                    decoration: const InputDecoration(
                      labelText: 'Matricule',
                      hintText: 'Ex: TECH-2024-001',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre matricule';
                      }
                      if (value.trim().length < 3) {
                        return 'Le matricule doit contenir au moins 3 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Mot de passe
                  TextFormField(
                    controller: _motDePasseController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      hintText: 'Entrez votre mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Message d'erreur
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppTheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bouton de connexion
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Se connecter'),
                  ),

              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}