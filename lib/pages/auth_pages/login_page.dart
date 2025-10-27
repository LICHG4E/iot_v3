import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iot_v3/constants/app_constants.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../../app_theme/theme_provider.dart';
import '../../constants/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isObscure = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigation handled by StreamBuilder in main_page.dart
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }
      AppWidgets.showSnackBar(
        context: context,
        message: message,
        type: SnackBarType.error,
      );
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      AppWidgets.showSnackBar(
        context: context,
        message: 'An unexpected error occurred',
        type: SnackBarType.error,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? [
                    theme.primaryColor.withOpacity(0.1),
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    theme.scaffoldBackgroundColor,
                    theme.primaryColor.withOpacity(0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Theme toggle button
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<ThemeProvider>(
                  builder: (context, provider, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          provider.isLight ? Icons.dark_mode : Icons.light_mode,
                        ),
                        onPressed: () => provider.toggleTheme(!provider.isLight),
                        tooltip: provider.isLight ? 'Dark Mode' : 'Light Mode',
                      ),
                    );
                  },
                ),
              ),

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                      vertical: 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo/Animation
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              height: size.height * 0.25,
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: Consumer<ThemeProvider>(
                                builder: (context, provider, _) {
                                  return RiveAnimation.asset(
                                    provider.isLight ? AppConstants.plantLogoLightPath : AppConstants.plantLogoDarkPath,
                                    fit: BoxFit.contain,
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Welcome text
                          Text(
                            'Welcome Back!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),

                          Text(
                            'Sign in to continue',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined, color: theme.primaryColor),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: isObscure,
                            textInputAction: TextInputAction.done,
                            enabled: !_isLoading,
                            onFieldSubmitted: (_) => login(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icon(Icons.lock_outlined, color: theme.primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isObscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () => setState(() => isObscure = !isObscure),
                              ),
                            ),
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

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : () => Navigator.pushNamed(context, forgotPasswordPage),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Login button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: theme.textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : () => Navigator.pushNamed(context, registerPage),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
