import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Estilo común de las cajas de texto de la app.
InputDecoration appInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
  Widget? suffixIcon,
  String? prefixText,
  String? helperText,
}) {
  final scheme = Theme.of(context).colorScheme;
  final outline = AppTheme.outlineOf(context);

  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helperText,
    prefixText: prefixText,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppTheme.fieldOf(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(outline),
    enabledBorder: border(outline),
    focusedBorder: border(scheme.primary, 1.8),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 1.8),
  );
}

/// Muestra un mensaje flotante (éxito o error).
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  IconData? icon,
}) {
  final scheme = Theme.of(context).colorScheme;
  final foreground = isError ? scheme.onError : scheme.onInverseSurface;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: isError ? scheme.error : scheme.inverseSurface,
      content: Row(
        children: [
          Icon(
            icon ??
                (isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded),
            color: foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    ),
  );
}
