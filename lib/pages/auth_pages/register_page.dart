import 'package:flutter/material.dart';
import 'package:iot_v3/constants/app_constants.dart';
import 'package:iot_v3/constants/routes.dart';
import 'package:iot_v3/pages/auth_pages/controllers/auth_controller.dart';
import 'package:iot_v3/pages/auth_pages/widgets/auth_page_template.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

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
  bool _passwordObscure = true;
  bool _confirmObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<AuthController>();
    await controller.register(_emailController.text, _passwordController.text);
    if (!mounted) return;
    if (controller.errorMessage != null) {
      AppWidgets.showSnackBar(
        context: context,
        message: controller.errorMessage!,
        type: SnackBarType.error,
      );
    } else {
      AppWidgets.showSnackBar(
        context: context,
        message: 'Verification email sent. Please verify to continue.',
        type: SnackBarType.info,
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        mainPage,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<AuthController>().isRegisterLoading;

    return AuthPageTemplate(
      showBackButton: true,
      illustration: const _RegisterHeroIllustration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create your account',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Securely sync devices, receive alerts, and manage your greenhouse anywhere.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(AppConstants.emailPattern).hasMatch(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              obscureText: _passwordObscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_passwordObscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _passwordObscure = !_passwordObscure),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please create a password';
                }
                if (value.length < AppConstants.minPasswordLength) {
                  return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                }
                final hasNumber = value.contains(RegExp(r'[0-9]'));
                if (!hasNumber) {
                  return 'Include at least one number for stronger security';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              textInputAction: TextInputAction.done,
              enabled: !isLoading,
              obscureText: _confirmObscure,
              onFieldSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_person_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_confirmObscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _confirmObscure = !_confirmObscure),
                ),
              ),
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _handleRegister,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?', style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterHeroIllustration extends StatelessWidget {
  const _RegisterHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return const Hero(
      tag: 'app_logo',
      child: SizedBox(
        height: 180,
        child: _RegisterLogoAnimation(),
      ),
    );
  }
}

class _RegisterLogoAnimation extends StatelessWidget {
  const _RegisterLogoAnimation();

  @override
  Widget build(BuildContext context) {
    return const RiveAnimation.asset(AppConstants.plantAnimationPath);
  }
}
