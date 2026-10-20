import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'product_widgets.dart';

/// Pantalla de error (por ejemplo, sin internet) con botón para reintentar.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.isConnectionError = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isConnectionError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnectionError
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 44,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isConnectionError ? 'Sin conexión a internet' : 'Algo salió mal',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío (sin productos o sin resultados de búsqueda).
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = actionLabel;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (label != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: Icon(actionIcon),
                label: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Aviso compacto (por ejemplo: "Sin conexión, mostrando datos guardados").
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = actionLabel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                message,
                style: TextStyle(
                  color: scheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (label != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer,
              ),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}

/// Esqueleto animado mientras carga el catálogo.
class ProductGridSkeleton extends StatefulWidget {
  const ProductGridSkeleton({super.key});

  @override
  State<ProductGridSkeleton> createState() => _ProductGridSkeletonState();
}

class _ProductGridSkeletonState extends State<ProductGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: productGridDelegate,
        itemCount: 8,
        itemBuilder: (context, index) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final block = AppTheme.outlineOf(context);

    Widget bar(double widthFactor, double height) {
      return FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: block,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 142, color: block.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(0.45, 16),
                const SizedBox(height: 12),
                bar(1, 12),
                const SizedBox(height: 6),
                bar(0.8, 12),
                const SizedBox(height: 16),
                bar(0.6, 10),
                const SizedBox(height: 6),
                bar(0.5, 10),
                const SizedBox(height: 18),
                bar(0.35, 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
