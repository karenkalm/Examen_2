import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/categories.dart';
import '../../core/ui_helpers.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/api_exception.dart';
import '../../widgets/animations.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/state_views.dart';
import 'product_form_screen.dart';

/// UI "Detalles" de un producto.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _lastKnown;
  bool _isDeleting = false;

  Future<void> _edit(Product product) async {
    final saved = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (!mounted) return;
    if (saved == null) return;
    showAppSnackBar(context, 'Cambios guardados');
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDeleteProductDialog(context, product);
    if (!mounted) return;
    if (!confirmed) return;
    setState(() => _isDeleting = true);
    try {
      await context.read<ProductProvider>().deleteProduct(product);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showAppSnackBar(
        context,
        'Producto eliminado',
        icon: Icons.delete_outline_rounded,
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showAppSnackBar(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Siempre muestra la versión más reciente (por si se editó).
    final product = context.select<ProductProvider, Product?>(
          (provider) => provider.findById(widget.productId),
        ) ??
        _lastKnown;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyStateView(
          icon: Icons.inventory_2_outlined,
          title: 'Producto no disponible',
          message: 'Es posible que haya sido eliminado.',
        ),
      );
    }
    _lastKnown = product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del producto'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: _isDeleting ? null : () => _edit(product),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: _isDeleting ? null : () => _delete(product),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final image = _DetailImage(
            product: product,
            height: isWide ? 460 : 300,
          );
          final info = FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: _ProductInfo(product: product),
          );

          if (isWide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: image),
                      const SizedBox(width: 32),
                      Expanded(flex: 6, child: info),
                    ],
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [image, const SizedBox(height: 20), info],
            ),
          );
        },
      ),
      bottomNavigationBar: _BottomActions(
        isBusy: _isDeleting,
        onEdit: () => _edit(product),
        onDelete: () => _delete(product),
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.product, required this.height});

  final Product product;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: height,
        child: Hero(
          tag: productHeroTag(product.id),
          child: ProductImage(
            url: product.image,
            padding: const EdgeInsets.all(28),
          ),
        ),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CategoryTag(category: product.category, large: true),
            if (product.isLocal) const NewBadge(),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          product.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (product.hasRating)
          Row(
            children: [
              RatingStars(rate: product.rating.rate),
              const SizedBox(width: 8),
              Text(
                product.rating.rate.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '(${product.rating.count} reseñas)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
            ],
          )
        else
          Text('Sin calificaciones todavía', style: muted),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Precio', style: muted),
                    Text(
                      product.formattedPrice,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.sell_rounded, color: scheme.primary, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Descripción',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.55,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Información',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _InfoGrid(
          items: [
            (Icons.tag_rounded, 'ID', '#${product.id}'),
            (
              ProductCategories.icon(product.category),
              'Categoría',
              ProductCategories.label(product.category),
            ),
            (
              Icons.reviews_outlined,
              'Reseñas',
              product.hasRating ? '${product.rating.count}' : '0',
            ),
            (
              product.isLocal ? Icons.phone_android_rounded : Icons.cloud_outlined,
              'Origen',
              product.isLocal ? 'Creado en la app' : 'FakeStore API',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (icon, label, value) in items)
              SizedBox(
                width: tileWidth,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineOf(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardOf(context),
        border: Border(top: BorderSide(color: AppTheme.outlineOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
