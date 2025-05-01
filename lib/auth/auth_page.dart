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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(ctx).colorScheme.error),
            const SizedBox(width: 10),
            const Text('Authentication Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoadingGoogle || _isLoadingEmail) return;
    setState(() => _isLoadingGoogle = true);
    final navigator = Navigator.of(context);

    User? user;
    String? errorMessage;
    try {
      user = await _authService.signInWithGoogle();
      if (user == null) {
        print("[AuthPage] Google Sign In returned null (possibly cancelled).");
      }
    } on FirebaseAuthException catch (e) {
      print(
          "[AuthPage] FirebaseAuthException during Google Sign-In: ${e.code}");
      errorMessage = _getFirebaseAuthErrorMessage(e);
    } catch (e) {
      print("[AuthPage] UNEXPECTED ERROR during Google Sign-In: $e");
      errorMessage = "An unexpected error occurred during Google Sign-In.";
    } finally {
      if (mounted) {
        setState(() => _isLoadingGoogle = false);
      }
    }

    if (!navigator.mounted) return;
    if (user != null) {
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    } else if (errorMessage != null) {
      _showErrorDialog(errorMessage);
    }
  }

  Future<void> _submitEmailForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_isLoadingGoogle || _isLoadingEmail) return;
    setState(() => _isLoadingEmail = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final navigator = Navigator.of(context);

    User? user;
    String? errorMessage;

    try {
      if (_isLoginMode) {
        print("[AuthPage] Attempting Email Sign-In...");
        user = await _authService.signInWithEmailPassword(email, password);
        if (user == null)
          errorMessage = _getFirebaseAuthErrorMessage(FirebaseAuthException(
              code: 'invalid-credential'));
      } else {
        print("[AuthPage] Attempting Email Sign-Up...");
        user = await _authService.signUpWithEmailPassword(email, password);
        if (user == null)
          errorMessage =
          "Sign up failed. Please check details or try a different email.";
      }
    } on FirebaseAuthException catch (e) {
      print("[AuthPage] FirebaseAuthException during Email Auth: ${e.code}");
      errorMessage = _getFirebaseAuthErrorMessage(e);
    } catch (e) {
      print("[AuthPage] Error during Email Auth: $e");
      errorMessage = "An unexpected error occurred.";
    } finally {
      if (mounted) {
        setState(() => _isLoadingEmail = false);
      }
    }

    if (!navigator.mounted) return;
    if (user != null) {
      print("[AuthPage] Email Auth successful. Navigating home.");
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      _showErrorDialog(
          errorMessage ?? 'An unknown authentication error occurred.');
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    print(
        "[AuthPage] Handling FirebaseAuthException: Code: ${e.code}, Message: ${e.message}");
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists for that email address. Please try logging in or use a different email.';
      case 'user-not-found':
        return 'No account found for this email address. Have you signed up?';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'invalid-email':
        return 'The email address format is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email but was created using a different sign-in method (like Google). Try signing in using that method.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not currently enabled.';
      default:
        return 'An unknown authentication error occurred. Please try again later. (Code: ${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _isLoadingGoogle || _isLoadingEmail;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? "Login" : "Sign Up"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.eco_rounded,
                    size: 60, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 30),
                Text(
                  _isLoginMode ? "Welcome Back!" : "Create Account",
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoadingGoogle
                      ? const Padding(
                    key: ValueKey('google_loader'),
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Center(
                        child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 3))),
                  )
                      : ElevatedButton.icon(
                    key: const ValueKey('google_button'),
                    icon: Image.asset('assets/google_logo.png',
                        height: 22.0,
                        errorBuilder: (c, e, s) => const Icon(
                            Icons.g_mobiledata_outlined,
                            size: 28,
                            color: Colors.redAccent)),
                    label: const Text('Continue with Google'),
                    onPressed: isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.grey[850],
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                if (!isLoading)
                  Row(children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child:
                      Text("OR", style: TextStyle(color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                const SizedBox(height: 25),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  obscureText: true,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) =>
                  isLoading ? null : _submitEmailForm(),
                ),
                const SizedBox(height: 25),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoadingEmail
                      ? const Padding(
                    key: ValueKey('email_loader'),
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Center(
                        child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 3))),
                  )
                      : Column(
                    key: const ValueKey('email_buttons'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: isLoading ? null : _submitEmailForm,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text(_isLoginMode
                            ? 'Sign In with Email'
                            : 'Sign Up with Email'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                          });
                          _formKey.currentState?.reset();
                        },
                        style: TextButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 10)),
                        child: Text(_isLoginMode
                            ? "Don't have an account? Sign Up"
                            : "Already have an account? Sign In"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}