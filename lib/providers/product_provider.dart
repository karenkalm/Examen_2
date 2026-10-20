import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/categories.dart';
import '../models/product.dart';
import '../services/api_exception.dart';
import '../services/product_local_store.dart';
import '../services/product_service.dart';

enum ProductsStatus { initial, loading, ready, error }

enum ProductSort {
  featured('Destacados'),
  priceLowToHigh('Precio: menor a mayor'),
  priceHighToLow('Precio: mayor a menor'),
  topRated('Mejor calificados'),
  alphabetical('Nombre (A-Z)');

  const ProductSort(this.label);

  final String label;
}

/// Estado del catálogo: carga, búsqueda/filtro y agregar/editar/eliminar.
class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductService? service, ProductLocalStore? store})
      : _service = service ?? ProductService(),
        _store = store ?? ProductLocalStore();

  final ProductService _service;
  final ProductLocalStore _store;

  List<Product> _products = const [];
  LocalChanges _changes = LocalChanges();
  bool _changesLoaded = false;
  final Set<int> _pendingIds = <int>{};

  ProductsStatus _status = ProductsStatus.initial;
  bool _isFetching = false;
  String? _errorMessage;
  bool _isConnectionError = false;
  bool _isShowingCachedData = false;

  String _query = '';
  String? _selectedCategory;
  ProductSort _sort = ProductSort.featured;

  // ── Lectura ────────────────────────────────────────────────────────

  List<Product> get allProducts => List.unmodifiable(_products);
  ProductsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnectionError => _isConnectionError;

  /// `true` cuando no se pudo actualizar y se muestran datos guardados.
  bool get isShowingCachedData => _isShowingCachedData;
  String get cachedDataMessage => _isConnectionError
      ? 'Sin conexión: mostrando el último catálogo guardado.'
      : 'No se pudo actualizar el catálogo. Mostrando datos guardados.';

  String get query => _query;
  String? get selectedCategory => _selectedCategory;
  ProductSort get sort => _sort;
  bool get hasActiveFilters => _query.isNotEmpty || _selectedCategory != null;
  bool get hasLocalChanges => !_changes.isEmpty;
  bool isPending(int id) => _pendingIds.contains(id);

  /// Categorías presentes en el catálogo (para los chips de filtro).
  List<String> get availableCategories {
    final categories = <String>{
      for (final p in _products)
        if (p.category.isNotEmpty) p.category,
    };
    return _sortCategories(categories);
  }

  /// Categorías que se pueden elegir en el formulario.
  List<String> get formCategories =>
      _sortCategories({...ProductCategories.defaults, ...availableCategories});

  /// Productos después de aplicar búsqueda, categoría y orden.
  List<Product> get visibleProducts {
    final search = _normalize(_query.trim());
    final result = _products.where((product) {
      if (_selectedCategory != null && product.category != _selectedCategory) {
        return false;
      }
      if (search.isEmpty) return true;
      return _normalize(product.title).contains(search) ||
          _normalize(product.description).contains(search) ||
          _normalize(product.category).contains(search) ||
          _normalize(ProductCategories.label(product.category))
              .contains(search);
    }).toList();

    switch (_sort) {
      case ProductSort.featured:
        return result;
      case ProductSort.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.topRated:
        result.sort((a, b) => b.rating.rate.compareTo(a.rating.rate));
      case ProductSort.alphabetical:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return result;
  }

  Product? findById(int id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  // ── Búsqueda y filtros ─────────────────────────────────────────────

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setCategory(String? category) {
    if (category == _selectedCategory) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSort(ProductSort sort) {
    if (sort == _sort) return;
    _sort = sort;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _selectedCategory = null;
    notifyListeners();
  }

  // ── Carga desde la API ─────────────────────────────────────────────

  /// Descarga el catálogo. Si no hay internet usa el último guardado.
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!refresh || _products.isEmpty) _status = ProductsStatus.loading;
    notifyListeners();

    try {
      if (!_changesLoaded) {
        _changes = await _store.readChanges();
        _changesLoaded = true;
      }
      final apiProducts = await _service.fetchProducts();
      _products = _changes.applyTo(apiProducts);
      _status = ProductsStatus.ready;
      _errorMessage = null;
      _isConnectionError = false;
      _isShowingCachedData = false;
      unawaited(_store.saveCache(apiProducts));
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isConnectionError = e.isConnectionError;
      await _useCacheOrFail();
    } catch (_) {
      _errorMessage = 'Ocurrió un error inesperado al cargar el catálogo.';
      _isConnectionError = false;
      await _useCacheOrFail();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> _useCacheOrFail() async {
    if (_products.isEmpty) {
      final cached = await _store.readCache();
      if (cached.isNotEmpty) _products = _changes.applyTo(cached);
    }
    if (_products.isEmpty) {
      _status = ProductsStatus.error;
      _isShowingCachedData = false;
    } else {
      _status = ProductsStatus.ready;
      _isShowingCachedData = true;
    }
  }

  // ── Agregar / editar / eliminar ────────────────────────────────────

  /// POST /products y agrega el producto al inicio del catálogo.
  Future<Product> addProduct(Product draft) {
    return _guard(() async {
      final created = await _service.createProduct(draft);

      // La API siempre regresa id 21, así que se asegura un id único.
      final usedIds = _products.map((p) => p.id).toSet();
      var newId = created.id;
      if (newId <= 0 || usedIds.contains(newId)) {
        newId = (usedIds.isEmpty ? 0 : usedIds.reduce(math.max)) + 1;
      }

      final product = draft.copyWith(id: newId, isLocal: true);
      _products = [product, ..._products];
      _changes.created.insert(0, product);
      await _store.saveChanges(_changes);
      notifyListeners();
      return product;
    });
  }

  /// PUT /products/{id} y reemplaza el producto en el catálogo.
  Future<Product> updateProduct(Product product) {
    return _guard(() async {
      _setPending(product.id, true);
      try {
        // Los productos creados en la app no existen en el servidor.
        if (!product.isLocal) await _service.updateProduct(product);

        final index = _products.indexWhere((p) => p.id == product.id);
        if (index == -1) {
          throw const ApiException('El producto ya no existe.');
        }
        final updated = List<Product>.of(_products);
        updated[index] = product;
        _products = updated;

        if (product.isLocal) {
          final i = _changes.created.indexWhere((p) => p.id == product.id);
          if (i != -1) _changes.created[i] = product;
        } else {
          _changes.edited[product.id] = product;
        }
        await _store.saveChanges(_changes);
        return product;
      } finally {
        _setPending(product.id, false);
      }
    });
  }

  /// DELETE /products/{id} y lo quita del catálogo.
  Future<void> deleteProduct(Product product) {
    return _guard(() async {
      _setPending(product.id, true);
      try {
        if (!product.isLocal) await _service.deleteProduct(product.id);

        _products = _products.where((p) => p.id != product.id).toList();
        if (product.isLocal) {
          _changes.created.removeWhere((p) => p.id == product.id);
        } else {
          _changes.edited.remove(product.id);
          _changes.deleted.add(product.id);
        }
        await _store.saveChanges(_changes);
      } finally {
        _setPending(product.id, false);
      }
    });
  }

  /// Borra los cambios locales y vuelve a descargar el catálogo original.
  Future<void> resetCatalog() async {
    _changes = LocalChanges();
    _changesLoaded = true;
    await _store.clearChanges();
    _products = const [];
    _isShowingCachedData = false;
    await loadProducts();
  }

  // ── Utilidades ─────────────────────────────────────────────────────

  void _setPending(int id, bool pending) {
    if (pending) {
      _pendingIds.add(id);
    } else {
      _pendingIds.remove(id);
    }
    notifyListeners();
  }

  /// Convierte cualquier error inesperado en un ApiException legible.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'No se pudo completar la operación. Inténtalo de nuevo.',
      );
    }
  }

  static List<String> _sortCategories(Set<String> categories) {
    return categories.toList()
      ..sort(
        (a, b) =>
            ProductCategories.label(a).compareTo(ProductCategories.label(b)),
      );
  }

  /// Minúsculas y sin acentos, para que "electronica" encuentre "Electrónica".
  static String _normalize(String value) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final buffer = StringBuffer();
    for (final char in value.toLowerCase().split('')) {
      final index = from.indexOf(char);
      buffer.write(index == -1 ? char : to[index]);
    }
    return buffer.toString();
  }
}
