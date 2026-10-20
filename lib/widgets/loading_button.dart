import 'package:flutter/material.dart';

/// Botón principal que muestra un indicador de carga mientras trabaja.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.onPrimary,
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}
