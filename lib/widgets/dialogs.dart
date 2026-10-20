import 'package:flutter/material.dart';

import '../models/product.dart';

/// Diálogo de confirmación. Regresa `true` si el usuario confirma.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  IconData? icon,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: icon == null
            ? null
            : Icon(icon, color: destructive ? scheme.error : scheme.primary),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    minimumSize: const Size(64, 44),
                  )
                : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Confirmación antes de eliminar un producto.
Future<bool> showDeleteProductDialog(BuildContext context, Product product) {
  return showConfirmDialog(
    context,
    icon: Icons.delete_outline_rounded,
    title: '¿Eliminar producto?',
    message: '"${product.title}" se eliminará del catálogo.',
    confirmLabel: 'Eliminar',
    destructive: true,
  );
}
