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
  // TODO: Ajouter contrôleurs et clé de formulaire pour Email/Pass
  // final TextEditingController _emailController = TextEditingController();
  // final TextEditingController _passwordController = TextEditingController();
  // final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // _emailController.dispose();
    // _passwordController.dispose();
    super.dispose();
  }

  // --- Connexion Google MODIFIÉE ---
  Future<void> _signInWithGoogle() async {
    if (_isLoadingGoogle) return;
    setState(() => _isLoadingGoogle = true);

    // Garde une référence au Navigator et ScaffoldMessenger
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    User? user; // Déclare user en dehors du try pour l'utiliser dans finally
    try {
      user = await _authService.signInWithGoogle();
    } finally {
      // Arrête le chargement dans tous les cas, si le widget est toujours monté
      if (mounted) {
        setState(() => _isLoadingGoogle = false);
      }
    }

    // Après la tentative, vérifie le résultat
    if (user == null) {
      // Affiche l'erreur si échec et widget monté
      if(mounted){
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In failed. Check network or configuration.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      // --- Connexion réussie : Redirige vers HomePage ---
      print("[AuthPage] Google Sign-In success. Navigating to /home and removing previous routes.");
      // Utilise pushNamedAndRemoveUntil pour vider la pile et aller à l'accueil
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      // --- FIN Redirection ---
    }
  }
  // --- FIN Connexion Google MODIFIÉE ---


  // --- Méthodes Email/Password (préparées pour redirection) ---
  Future<void> _signInWithEmail() async {
    // TODO: Ajouter la logique de connexion email ici...
    print("TODO: Sign in with Email");
    final navigator = Navigator.of(context); // Pour la navigation future
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email Sign-In not implemented yet.'))
    );
    // Exemple de redirection si succès:
    // User? user = await _authService.signInWithEmailPassword(...);
    // if (user != null && navigator.mounted) {
    //   navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    // }
  }

  Future<void> _signUpWithEmail() async {
    // TODO: Ajouter la logique d'inscription email ici...
    print("TODO: Sign up with Email");
    final navigator = Navigator.of(context); // Pour la navigation future
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email Sign-Up not implemented yet.'))
    );
    // Exemple de redirection si succès:
    // User? user = await _authService.signUpWithEmailPassword(...);
    // if (user != null && navigator.mounted) {
    //   navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    // }
  }
  // --- Fin Email/Password ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login / Sign Up"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
          // key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.eco_rounded, size: 60, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 30),
              Text(
                "Connect to GreenWatch",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),

              // Bouton Google
              if (_isLoadingGoogle)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                ))
              else
                ElevatedButton.icon(
                  icon: Image.asset('assets/google_logo.png', height: 22.0, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata_outlined, size: 28, color: Colors.redAccent)),
                  label: const Text('Continue with Google'),
                  onPressed: _signInWithGoogle, // Fonction modifiée
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.grey[850],
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    elevation: 1,
                  ),
                ),

              const SizedBox(height: 25),
              Row(children: <Widget>[ const Expanded(child: Divider()), Padding( padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.grey[600])), ), const Expanded(child: Divider()), ]),
              const SizedBox(height: 25),

              // Champs Email/Password
              TextFormField( decoration: const InputDecoration( labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder(), filled: true, ), keyboardType: TextInputType.emailAddress, ),
              const SizedBox(height: 15),
              TextFormField( decoration: const InputDecoration( labelText: 'Password', prefixIcon: Icon(Icons.lock_outlined), border: OutlineInputBorder(), filled: true, ), obscureText: true, ),
              const SizedBox(height: 25),

              // Boutons Email/Password
              if (_isLoadingEmail)
                const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 14.0), child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)), ))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton( onPressed: _signInWithEmail, style: ElevatedButton.styleFrom( minimumSize: const Size(double.infinity, 50), padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), ), child: const Text('Sign In with Email'), ),
                    const SizedBox(height: 10),
                    TextButton( onPressed: _signUpWithEmail, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text("Don't have an account? Sign Up"), ),
                  ],
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}