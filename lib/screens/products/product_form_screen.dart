import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/categories.dart';
import '../../core/constants.dart';
import '../../core/ui_helpers.dart';
import '../../core/validators.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/api_exception.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/product_widgets.dart';

/// Formulario para agregar o editar un producto (con validaciones).
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  /// Si viene un producto, el formulario funciona en modo "editar".
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageController;
  late final String _initialSignature;

  String? _category;
  String _previewImage = '';
  Timer? _previewDebounce;
  bool _isSaving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _titleController = TextEditingController(text: product?.title ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _imageController = TextEditingController(text: product?.image ?? '');
    _category = product?.category;
    _previewImage = product?.image ?? '';
    _initialSignature = _signature();

    _titleController.addListener(_refresh);
    _priceController.addListener(_refresh);
    _descriptionController.addListener(_refresh);
    _imageController.addListener(_onImageChanged);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  String _signature() => [
        _titleController.text,
        _priceController.text,
        _descriptionController.text,
        _imageController.text,
        _category ?? '',
      ].join('|');

  bool get _hasChanges => _signature() != _initialSignature;

  void _refresh() => setState(() {});

  /// Actualiza la vista previa de la imagen cuando se deja de escribir.
  void _onImageChanged() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final url = _imageController.text.trim();
      setState(() {
        _previewImage = Validators.imageUrl(url) == null ? url : '';
      });
    });
    // Para que el botón "atrás" sepa si hay cambios sin guardar.
    _refresh();
  }

  void _useSampleImage() {
    HapticFeedback.selectionClick();
    _imageController.text = ApiConfig.sampleImage;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      HapticFeedback.mediumImpact();
      showAppSnackBar(
        context,
        'Revisa los campos marcados en rojo',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<ProductProvider>();
    final original = widget.product;
    final draft = Product(
      id: original?.id ?? 0,
      title: _titleController.text.trim(),
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
      description: _descriptionController.text.trim(),
      category: _category ?? '',
      image: _imageController.text.trim(),
      rating: original?.rating ?? const Rating.empty(),
      isLocal: original?.isLocal ?? true,
    );

    try {
      final saved = original == null
          ? await provider.addProduct(draft)
          : await provider.updateProduct(draft);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAppSnackBar(context, e.message, isError: true);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showConfirmDialog(
      context,
      icon: Icons.edit_off_outlined,
      title: '¿Descartar cambios?',
      message: 'Tienes cambios sin guardar en este producto.',
      cancelLabel: 'Seguir editando',
      confirmLabel: 'Descartar',
      destructive: true,
    );
    if (!mounted) return;
    if (discard) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categories = context.select<ProductProvider, List<String>>(
      (provider) => provider.formCategories,
    );
    final isEditing = widget.isEditing;

    return PopScope<Product>(
      canPop: _isSaving || !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Editar producto' : 'Nuevo producto'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    _PreviewCard(
                      title: _titleController.text.trim(),
                      price: _priceController.text.trim(),
                      category: _category,
                      imageUrl: _previewImage,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 80,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: appInputDecoration(
                        context,
                        label: 'Título',
                        hint: 'Ej. Audífonos inalámbricos',
                        icon: Icons.title_rounded,
                      ),
                      validator: Validators.productTitle,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d{0,2}'),
                        ),
                      ],
                      decoration: appInputDecoration(
                        context,
                        label: 'Precio (USD)',
                        hint: '0.00',
                        icon: Icons.attach_money_rounded,
                      ),
                      validator: Validators.price,
                    ),
                    const SizedBox(height: 20),
                    FormField<String>(
                      initialValue: _category,
                      validator: Validators.category,
                      builder: (field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Categoría',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final category in categories)
                                  ChoiceChip(
                                    label: Text(
                                      ProductCategories.label(category),
                                    ),
                                    avatar: Icon(
                                      ProductCategories.icon(category),
                                      size: 18,
                                    ),
                                    selected: field.value == category,
                                    showCheckmark: false,
                                    onSelected: (_) {
                                      HapticFeedback.selectionClick();
                                      field.didChange(category);
                                      setState(() => _category = category);
                                    },
                                  ),
                              ],
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  left: 12,
                                ),
                                child: Text(
                                  field.errorText ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.error,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _imageController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: appInputDecoration(
                        context,
                        label: 'URL de la imagen',
                        hint: 'https://...',
                        icon: Icons.image_outlined,
                      ),
                      validator: Validators.imageUrl,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _useSampleImage,
                        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                        label: const Text('Usar imagen de ejemplo'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 600,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: appInputDecoration(
                        context,
                        label: 'Descripción',
                        hint: 'Describe el producto, materiales, uso...',
                      ).copyWith(alignLabelWithHint: true),
                      validator: Validators.description,
                    ),
                    const SizedBox(height: 20),
                    LoadingButton(
                      label: isEditing ? 'Guardar cambios' : 'Agregar producto',
                      icon: isEditing
                          ? Icons.save_outlined
                          : Icons.add_circle_outline_rounded,
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista previa en vivo de cómo se verá el producto.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.price,
    required this.category,
    required this.imageUrl,
  });

  final String title;
  final String price;
  final String? category;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parsedPrice = double.tryParse(price.replaceAll(',', '.')) ?? 0;
    final selectedCategory = category;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 84,
                height: 84,
                child: ProductImage(
                  key: ValueKey(imageUrl),
                  url: imageUrl,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VISTA PREVIA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.isEmpty ? 'Nombre del producto' : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: title.isEmpty ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${parsedPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                      if (selectedCategory != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: CategoryTag(category: selectedCategory),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
