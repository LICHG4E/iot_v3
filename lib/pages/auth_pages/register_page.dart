import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import '../../app_theme/theme_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showEmailVerificationOverlay = false;
  late int _timerCountdown;
  late String _timerDisplay;
  late UserCredential userCredential;

  Future<void> register() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new user with email and password
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Add user data to Firestore
      final userUID = userCredential.user?.uid; // Get the user's UID
      if (userUID != null) {
        await FirebaseFirestore.instance.collection('users').doc(userUID).set({
          'userUID': userUID,
          'devices': [], // Initialize with an empty array
        });
      }

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Show email verification overlay
      setState(() {
        _showEmailVerificationOverlay = true;
        _timerCountdown = 5; // 5 seconds countdown
        _timerDisplay = '$_timerCountdown';
      });

      // Start a timer for the countdown
      startTimer();
    } catch (e) {
      // Handle errors (e.g., email already in use, weak password)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_timerCountdown > 0) {
        setState(() {
          _timerCountdown--;
          _timerDisplay = '$_timerCountdown';
        });
        startTimer();
      } else {
        setState(() {
          _timerDisplay = '0';
        });
      }
    });
  }

  void goToHomepage() {
    // Navigate to the homepage (or any other page you want)
    Navigator.pushReplacementNamed(context, '/home/', arguments: userCredential.user?.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: Consumer<ThemeProvider>(
          builder: (context, provider, child) {
            return Row(
              children: [
                const SizedBox(width: 16),
                Switch(
                  value: provider.isLight,
                  onChanged: (value) {
                    setState(() {
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                    });
                  },
                  thumbIcon:
                      WidgetStatePropertyAll(provider.isLight ? const Icon(Icons.light_mode) : const Icon(Icons.dark_mode)),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            );
          },
        ),
        leadingWidth: 100,
        scrolledUnderElevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 300,
                    child: RiveAnimation.asset(
                      'assets/animations/plants.riv',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create an Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zAZ0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              register();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'Register',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Already have an account? Login here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showEmailVerificationOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Please verify your email address. Your account will be deleted if not verified.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Time remaining: $_timerDisplay seconds',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _timerCountdown == 0 ? goToHomepage : null,
                          child: _timerCountdown == 0 ? const Text('Okay') : Text('Okay ($_timerDisplay)'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
