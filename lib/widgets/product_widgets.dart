import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/categories.dart';

/// Tag del Hero que anima la imagen entre la lista y los detalles.
String productHeroTag(int id) => 'product-image-$id';

/// Distribución responsiva del catálogo: 2 columnas en celular y más en
/// tablet o escritorio.
const SliverGridDelegateWithMaxCrossAxisExtent productGridDelegate =
    SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 260,
  mainAxisExtent: 318,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
);

/// Imagen del producto con indicador de carga y respaldo si falla.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.padding = const EdgeInsets.all(14),
  });

  final String url;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: padding,
        child: url.isEmpty
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  final expected = progress.expectedTotalBytes;
                  return Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        value: expected == null
                            ? null
                            : progress.cumulativeBytesLoaded / expected,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}

/// Etiqueta con el ícono y nombre de la categoría.
class CategoryTag extends StatelessWidget {
  const CategoryTag({super.key, required this.category, this.large = false});

  final String category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ProductCategories.icon(category),
            size: large ? 16 : 12,
            color: scheme.onPrimaryContainer,
          ),
          SizedBox(width: large ? 6 : 4),
          Flexible(
            child: Text(
              ProductCategories.label(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: large ? 13 : 11,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estrellas de calificación (admite medias estrellas).
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rate, this.size = 18});

  final double rate;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rate >= i
                ? Icons.star_rounded
                : rate >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: AppTheme.star,
          ),
      ],
    );
  }
}

/// Insignia para productos creados desde la app.
class NewBadge extends StatelessWidget {
  const NewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.star,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'NUEVO',
        style: TextStyle(
          color: Color(0xFF3B2600),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
