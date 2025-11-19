import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_theme/theme_provider.dart';

class AuthPageTemplate extends StatelessWidget {
  const AuthPageTemplate({
    super.key,
    required this.child,
    this.illustration,
    this.showBackButton = false,
    this.onBack,
  });

  final Widget child;
  final Widget? illustration;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: theme.brightness == Brightness.light
          ? [theme.colorScheme.surface, theme.scaffoldBackgroundColor]
          : [theme.scaffoldBackgroundColor, theme.colorScheme.surfaceContainerHighest.withOpacity(0.2)],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              if (showBackButton)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Back',
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: _ThemeToggle(),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (illustration != null) ...[
                          illustration!,
                          const SizedBox(height: 24),
                        ],
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: child,
                          ),
                        ),
                      ],
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

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    return _CircleIconButton(
      icon: provider.isLight ? Icons.dark_mode : Icons.light_mode,
      tooltip: provider.isLight ? 'Switch to dark mode' : 'Switch to light mode',
      onPressed: () => provider.toggleTheme(!provider.isLight),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        icon: Icon(icon, color: theme.colorScheme.onSurface),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
