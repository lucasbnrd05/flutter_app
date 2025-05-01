// lib/auth/auth_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoadingGoogle = false;
  bool _isLoadingEmail = false;
  final AuthService _authService = AuthService();

  // --- Décommenter et initialiser ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Clé pour le formulaire
  // --- Fin ---

  // Variable pour basculer entre Login et Sign Up
  bool _isLoginMode = true;


  @override
  void dispose() {
    // --- Disposer les contrôleurs ---
    _emailController.dispose();
    _passwordController.dispose();
    // --- Fin ---
    super.dispose();
  }

  Future<void> _signInWithGoogle() async { /* ... inchangé ... */ if (_isLoadingGoogle) return; setState(() => _isLoadingGoogle = true); final navigator = Navigator.of(context); final scaffoldMessenger = ScaffoldMessenger.of(context); User? user; try { user = await _authService.signInWithGoogle(); } finally { if (mounted) { setState(() => _isLoadingGoogle = false); } } if (user == null) { if(mounted){ scaffoldMessenger.showSnackBar( const SnackBar( content: Text('Google Sign-In failed. Check network or configuration.'), backgroundColor: Colors.redAccent, ), ); } } else { print("[AuthPage] Google Sign-In success. Navigating to /home and removing previous routes."); navigator.pushNamedAndRemoveUntil('/home', (route) => false); } }

  // --- Méthodes Email/Password MODIFIÉES ---
  Future<void> _submitEmailForm() async {
    // 1. Valide le formulaire
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Ne fait rien si le formulaire n'est pas valide
    }
    // Empêche double clic pendant chargement
    if (_isLoadingEmail) return;

    // 2. Démarre le chargement
    setState(() => _isLoadingEmail = true);

    // 3. Récupère les valeurs
    final email = _emailController.text.trim();
    final password = _passwordController.text; // Pas de trim sur le mot de passe

    // Références Navigator/ScaffoldMessenger avant l'async
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    User? user;
    String? errorMessage;

    try {
      // 4. Appelle la bonne méthode du service selon le mode
      if (_isLoginMode) {
        print("[AuthPage] Attempting Email Sign-In...");
        user = await _authService.signInWithEmailPassword(email, password);
        if (user == null) errorMessage = "Login failed. Check email/password.";
      } else {
        print("[AuthPage] Attempting Email Sign-Up...");
        user = await _authService.signUpWithEmailPassword(email, password);
        if (user == null) errorMessage = "Sign up failed. Email might be in use or password too weak.";
      }
    } catch (e) { // Capture d'autres erreurs potentielles
      print("[AuthPage] Error during Email Auth: $e");
      errorMessage = "An unexpected error occurred.";
    } finally {
      // Arrête le chargement si toujours monté
      if (mounted) {
        setState(() => _isLoadingEmail = false);
      }
    }

    // 5. Gère le résultat
    if (!navigator.mounted) return; // Vérifie à nouveau si le widget existe

    if (user != null) {
      // Succès : Navigue vers Home
      print("[AuthPage] Email Auth successful. Navigating home.");
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      // Échec : Affiche l'erreur
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'An unknown error occurred.'), // Message d'erreur
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  // --- Fin Méthodes Email/Password ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? "Login" : "Sign Up"), // Titre dynamique
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
          // --- Ajout du Widget Form ---
          child: Form(
            key: _formKey, // Lie la clé au formulaire
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.eco_rounded, size: 60, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 30),
                Text(
                  _isLoginMode ? "Welcome Back!" : "Create Account", // Texte dynamique
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 40),

                // Bouton Google (inchangé)
                if (!_isLoadingEmail && !_isLoadingGoogle) // Cache si l'autre loader est actif
                  ElevatedButton.icon( icon: Image.asset( 'assets/google_logo.png', height: 22.0, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata_outlined, size: 28, color: Colors.redAccent) ), label: const Text('Continue with Google'), onPressed: _signInWithGoogle, style: ElevatedButton.styleFrom( foregroundColor: Colors.grey[850], backgroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300), ), elevation: 1, ), ),
                if (_isLoadingGoogle)
                  const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 14.0), child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)), )),

                const SizedBox(height: 25),
                if (!_isLoadingGoogle && !_isLoadingEmail) // Cache si l'autre loader est actif
                  Row(children: <Widget>[ const Expanded(child: Divider()), Padding( padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.grey[600])), ), const Expanded(child: Divider()), ]),
                const SizedBox(height: 25),

                // Champs Email/Password
                TextFormField(
                  controller: _emailController, // Lie le contrôleur
                  decoration: const InputDecoration( labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder(), filled: true, ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoadingEmail && !_isLoadingGoogle, // Désactive pendant chargement
                  // Validation simple
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    // Regex simple pour vérifier le format email
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null; // Valide
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController, // Lie le contrôleur
                  decoration: const InputDecoration( labelText: 'Password', prefixIcon: Icon(Icons.lock_outlined), border: OutlineInputBorder(), filled: true, ),
                  obscureText: true, // Masque le mot de passe
                  enabled: !_isLoadingEmail && !_isLoadingGoogle, // Désactive pendant chargement
                  // Validation simple
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null; // Valide
                  },
                ),
                const SizedBox(height: 25),

                // Boutons Email/Password
                if (_isLoadingEmail)
                  const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 14.0), child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)), ))
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        // Appelle la fonction de soumission du formulaire
                        onPressed: _isLoadingGoogle ? null : _submitEmailForm,
                        style: ElevatedButton.styleFrom( minimumSize: const Size(double.infinity, 50), padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), ),
                        // Texte dynamique Login/Sign Up
                        child: Text(_isLoginMode ? 'Sign In with Email' : 'Sign Up with Email'),
                      ),
                      const SizedBox(height: 10),
                      // Bouton pour basculer entre Login et Sign Up
                      TextButton(
                        onPressed: _isLoadingGoogle ? null : () {
                          setState(() {
                            _isLoginMode = !_isLoginMode; // Inverse le mode
                          });
                        },
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                        // Texte dynamique
                        child: Text(_isLoginMode
                            ? "Don't have an account? Sign Up"
                            : "Already have an account? Sign In"),
                      ),
                    ],
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}