import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/categories.dart';
import '../../core/ui_helpers.dart';
import '../../models/app_user.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/api_exception.dart';
import '../../widgets/animations.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/state_views.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

enum _MenuAction { reset, logout }

/// UI "Productos": catálogo con búsqueda, filtro por categoría y orden.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _searchController.text = provider.query;
    if (provider.status == ProductsStatus.initial) {
      // Se pide el catálogo a la API después del primer frame.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => provider.loadProducts(),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Acciones ───────────────────────────────────────────────────────

  void _openDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
  }

  Future<void> _openForm([Product? product]) async {
    final saved = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (!mounted) return;
    if (saved == null) return;
    showAppSnackBar(
      context,
      product == null ? 'Producto agregado al catálogo' : 'Cambios guardados',
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDeleteProductDialog(context, product);
    if (!mounted) return;
    if (!confirmed) return;
    try {
      await context.read<ProductProvider>().deleteProduct(product);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showAppSnackBar(
        context,
        'Producto eliminado',
        icon: Icons.delete_outline_rounded,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message, isError: true);
    }
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<ProductProvider>().clearFilters();
    FocusScope.of(context).unfocus();
  }

  Future<void> _resetCatalog() async {
    final confirmed = await showConfirmDialog(
      context,
      icon: Icons.restart_alt_rounded,
      title: '¿Restablecer catálogo?',
      message: 'Se descartarán los productos agregados, editados o '
          'eliminados en este dispositivo y se volverá a cargar el '
          'catálogo original de la API.',
      confirmLabel: 'Restablecer',
      destructive: true,
    );
    if (!mounted) return;
    if (!confirmed) return;
    await context.read<ProductProvider>().resetCatalog();
    if (!mounted) return;
    showAppSnackBar(context, 'Catálogo restablecido');
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      icon: Icons.logout_rounded,
      title: '¿Cerrar sesión?',
      message: 'Tendrás que ingresar tu usuario y contraseña de nuevo.',
      confirmLabel: 'Cerrar sesión',
    );
    if (!mounted) return;
    if (!confirmed) return;
    _searchController.clear();
    context.read<ProductProvider>().clearFilters();
    await context.read<AuthProvider>().logout();
  }

  void _showAccount(AppUser user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _AccountSheet(
        user: user,
        onLogout: () {
          Navigator.of(sheetContext).pop();
          _logout();
        },
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, AppUser?>((auth) => auth.user);
    final provider = context.watch<ProductProvider>();
    final visible = provider.visibleProducts;
    final showResultsHeader = provider.status == ProductsStatus.ready &&
        provider.allProducts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 16,
        title: _Greeting(
          user: user,
          onAvatarTap: user == null ? null : () => _showAccount(user),
        ),
        actions: [
          _SortMenu(current: provider.sort, onSelected: provider.setSort),
          PopupMenuButton<_MenuAction>(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              switch (action) {
                case _MenuAction.reset:
                  _resetCatalog();
                case _MenuAction.logout:
                  _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.reset,
                enabled: provider.hasLocalChanges,
                child: const ListTile(
                  leading: Icon(Icons.restart_alt_rounded),
                  title: Text('Restablecer catálogo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _MenuAction.logout,
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Cerrar sesión'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: _SearchField(
              controller: _searchController,
              onChanged: provider.setQuery,
            ),
          ),
          _CategoryBar(
            categories: provider.availableCategories,
            selected: provider.selectedCategory,
            onSelected: provider.setCategory,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: provider.isShowingCachedData
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: InfoBanner(
                      icon: Icons.cloud_off_rounded,
                      message: provider.cachedDataMessage,
                      actionLabel: 'Reintentar',
                      onAction: () => provider.loadProducts(refresh: true),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (showResultsHeader)
            _ResultsHeader(
              count: visible.length,
              sort: provider.sort,
              hasFilters: provider.hasActiveFilters,
              onClear: _clearFilters,
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(provider, visible),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildContent(ProductProvider provider, List<Product> visible) {
    if (provider.status == ProductsStatus.initial ||
        provider.status == ProductsStatus.loading) {
      return const ProductGridSkeleton(key: ValueKey('loading'));
    }

    if (provider.status == ProductsStatus.error) {
      return ErrorStateView(
        key: const ValueKey('error'),
        message: provider.errorMessage ?? 'No se pudo cargar el catálogo.',
        isConnectionError: provider.isConnectionError,
        onRetry: provider.loadProducts,
      );
    }

    if (provider.allProducts.isEmpty) {
      return EmptyStateView(
        key: const ValueKey('empty'),
        icon: Icons.inventory_2_outlined,
        title: 'Aún no hay productos',
        message: 'Agrega el primero con el botón "Agregar".',
        actionLabel: 'Recargar catálogo',
        onAction: () => provider.loadProducts(refresh: true),
      );
    }

    if (visible.isEmpty) {
      return EmptyStateView(
        key: const ValueKey('no-results'),
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        message: provider.query.trim().isEmpty
            ? 'No hay productos en esta categoría.'
            : 'No encontramos productos para "${provider.query.trim()}".',
        actionLabel: 'Limpiar filtros',
        actionIcon: Icons.clear_all_rounded,
        onAction: _clearFilters,
      );
    }

    return RefreshIndicator(
      key: const ValueKey('grid'),
      onRefresh: () => provider.loadProducts(refresh: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: productGridDelegate,
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final product = visible[index];
          return FadeSlideIn(
            key: ValueKey(product.id),
            delay: Duration(milliseconds: index < 8 ? index * 50 : 0),
            child: ProductCard(
              product: product,
              isBusy: provider.isPending(product.id),
              onTap: () => _openDetail(product),
              onEdit: () => _openForm(product),
              onDelete: () => _deleteProduct(product),
            ),
          );
        },
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, this.onAvatarTap});

  final AppUser? user;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Tooltip(
          message: 'Mi cuenta',
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hola, ${user?.firstName ?? 'invitado'} 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Explora y administra el catálogo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outline = AppTheme.outlineOf(context);

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, descripción o categoría',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            filled: true,
            fillColor: AppTheme.cardOf(context),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: border(outline),
            enabledBorder: border(outline),
            focusedBorder: border(scheme.primary, 1.6),
          ),
        );
      },
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = index == 0 ? null : categories[index - 1];
          return ChoiceChip(
            label: Text(
              category == null ? 'Todas' : ProductCategories.label(category),
            ),
            avatar: Icon(
              category == null
                  ? Icons.apps_rounded
                  : ProductCategories.icon(category),
              size: 18,
            ),
            selected: category == selected,
            showCheckmark: false,
            shape: const StadiumBorder(),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onSelected(category);
            },
          );
        },
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.count,
    required this.sort,
    required this.hasFilters,
    required this.onClear,
  });

  final int count;
  final ProductSort sort;
  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 2),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Text(
              count == 1 ? '1 producto' : '$count productos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (sort != ProductSort.featured) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '· ${sort.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (hasFilters)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Limpiar'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.current, required this.onSelected});

  final ProductSort current;
  final ValueChanged<ProductSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProductSort>(
      tooltip: 'Ordenar',
      initialValue: current,
      onSelected: onSelected,
      icon: Badge(
        isLabelVisible: current != ProductSort.featured,
        smallSize: 8,
        child: const Icon(Icons.swap_vert_rounded),
      ),
      itemBuilder: (context) => [
        for (final sort in ProductSort.values)
          CheckedPopupMenuItem(
            value: sort,
            checked: sort == current,
            child: Text(sort.label),
          ),
      ],
    );
  }
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '@${user.username} · ${user.email}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (user.isDemo) ...[
              const SizedBox(height: 12),
              const Chip(
                avatar: Icon(Icons.science_outlined, size: 18),
                label: Text('Cuenta de prueba'),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
