import 'package:flutter/material.dart';
import 'package:iot_v3/constants/app_constants.dart';
import 'package:iot_v3/pages/auth_pages/controllers/auth_controller.dart';
import 'package:iot_v3/pages/auth_pages/widgets/auth_page_template.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  Future<void> _resendEmail(BuildContext context) async {
    final controller = context.read<AuthController>();
    await controller.resendVerificationEmail();
    if (!context.mounted) return;
    if (controller.errorMessage != null) {
      AppWidgets.showSnackBar(
        context: context,
        message: controller.errorMessage!,
        type: SnackBarType.error,
      );
    } else {
      AppWidgets.showSnackBar(
        context: context,
        message: 'Verification email sent again. Please check your inbox.',
        type: SnackBarType.success,
      );
    }
  }

  Future<void> _refreshStatus(BuildContext context) async {
    final controller = context.read<AuthController>();
    await controller.refreshUser();
    if (!context.mounted) return;
    if (controller.status == AuthStatus.awaitingEmailVerification) {
      AppWidgets.showSnackBar(
        context: context,
        message: 'We still cannot detect a verified email. Try again in a few seconds.',
        type: SnackBarType.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final theme = Theme.of(context);

    return AuthPageTemplate(
      illustration: const SizedBox(
        height: 200,
        child: _VerifyEmailIllustration(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verify your email',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ve sent a secure link to ${controller.user?.email ?? 'your inbox'}.'
            ' Please confirm the email address before continuing.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.mark_email_read_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Check your spam folder if you can\'t find the email. The link expires in 15 minutes.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: controller.isVerificationLoading ? null : () => _resendEmail(context),
            icon: controller.isVerificationLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('Resend verification email'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _refreshStatus(context),
            icon: const Icon(Icons.refresh),
            label: const Text('I\'ve verified my email'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => controller.logout(),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _VerifyEmailIllustration extends StatelessWidget {
  const _VerifyEmailIllustration();

  @override
  Widget build(BuildContext context) {
    return const RiveAnimation.asset(
      AppConstants.mailAnimationPath,
      fit: BoxFit.contain,
    );
  }
}
