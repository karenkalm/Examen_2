import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/product.dart';
import 'product_widgets.dart';

enum _CardAction { edit, delete }

/// Tarjeta del catálogo: imagen, categoría, título, descripción y precio.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isBusy = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Muestra un indicador mientras se edita o elimina en la API.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 142,
                child: Hero(
                  tag: productHeroTag(product.id),
                  child: ProductImage(url: product.image),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CategoryTag(category: product.category),
                      const SizedBox(height: 6),
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          product.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.formattedPrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          if (product.hasRating) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppTheme.star,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.rate.toStringAsFixed(1),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Capa táctil encima de todo para que el efecto se vea sobre la imagen.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: isBusy ? null : onTap),
            ),
          ),
          if (product.isLocal)
            const Positioned(top: 10, left: 10, child: NewBadge()),
          Positioned(
            top: 6,
            right: 6,
            child: _CardMenu(
              enabled: !isBusy,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
          if (isBusy)
            Positioned.fill(
              child: ColoredBox(
                color: scheme.surface.withValues(alpha: 0.65),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 1,
      child: SizedBox(
        width: 36,
        height: 36,
        child: PopupMenuButton<_CardAction>(
          enabled: enabled,
          tooltip: 'Opciones',
          padding: EdgeInsets.zero,
          iconSize: 20,
          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF1F2933)),
          onSelected: (action) {
            switch (action) {
              case _CardAction.edit:
                onEdit();
              case _CardAction.delete:
                onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _CardAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: _CardAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                title: Text('Eliminar', style: TextStyle(color: scheme.error)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
