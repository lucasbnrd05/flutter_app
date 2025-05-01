// lib/ux_unit/login_required_widget.dart
import 'package:flutter/material.dart';

class LoginRequiredWidget extends StatelessWidget {
  final String featureName; // Le nom de la fonctionnalité bloquée

  const LoginRequiredWidget({
    super.key,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_outlined,
                size: 60, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 25),
            Text(
              'You must be logged in with Google or Email to access "$featureName".', // Message dynamique
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, height: 1.4),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Go to Login / Sign Up"),
              onPressed: () {
                // Navigue vers la page d'authentification
                // Assure-toi que la route '/auth' est définie dans main.dart
                Navigator.pushNamed(context, '/auth');
              },
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            )
          ],
        ),
      ),
    );
  }
}
