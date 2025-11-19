import 'package:flutter/material.dart';
import 'package:iot_v3/constants/app_constants.dart';
import 'package:iot_v3/pages/auth_pages/controllers/auth_controller.dart';
import 'package:iot_v3/pages/auth_pages/widgets/auth_page_template.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<AuthController>();
    await controller.sendPasswordReset(_emailController.text);
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
        message: 'Password reset email sent (if the address exists).',
        type: SnackBarType.success,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<AuthController>().isResetLoading;

    return AuthPageTemplate(
      showBackButton: true,
      illustration: SizedBox(
        height: 200,
        child: RiveAnimation.asset(
          AppConstants.mailAnimationPath,
          fit: BoxFit.contain,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trouble signing in?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email and we\'ll send you a secure link to reset your password.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.done,
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _handleReset,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }
}
