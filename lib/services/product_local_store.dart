import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// Cambios hechos desde la app.
///
/// La FakeStore API responde a POST, PUT y DELETE pero no guarda nada, así que
/// la app recuerda aquí lo que el usuario agregó, editó o eliminó.
class LocalChanges {
  LocalChanges({
    List<Product>? created,
    Map<int, Product>? edited,
    Set<int>? deleted,
  })  : created = created ?? <Product>[],
        edited = edited ?? <int, Product>{},
        deleted = deleted ?? <int>{};

  factory LocalChanges.fromJson(Map<String, dynamic> json) {
    List<Product> parseList(Object? value) {
      if (value is! List) return <Product>[];
      return value
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    }

    final deleted = json['deleted'];
    return LocalChanges(
      created: parseList(json['created'])
          .map((p) => p.copyWith(isLocal: true))
          .toList(),
      edited: {for (final p in parseList(json['edited'])) p.id: p},
      deleted: deleted is List
          ? deleted.whereType<num>().map((n) => n.toInt()).toSet()
          : <int>{},
    );
  }

  /// Productos creados (el más nuevo primero).
  final List<Product> created;
  final Map<int, Product> edited;
  final Set<int> deleted;

  bool get isEmpty => created.isEmpty && edited.isEmpty && deleted.isEmpty;

  /// Aplica los cambios locales sobre la lista que vino de la API.
  List<Product> applyTo(List<Product> apiProducts) {
    return [
      ...created,
      for (final product in apiProducts)
        if (!deleted.contains(product.id)) edited[product.id] ?? product,
    ];
  }

  Map<String, dynamic> toJson() => {
        'created': created.map((p) => p.toJson()).toList(),
        'edited': edited.values.map((p) => p.toJson()).toList(),
        'deleted': deleted.toList(),
      };
}

/// Guarda en el dispositivo el último catálogo descargado (para usarlo sin
/// internet) y los cambios locales.
class ProductLocalStore {
  static const String _cacheKey = 'products_cache_v1';
  static const String _changesKey = 'products_changes_v1';

  Future<void> saveCache(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_cacheKey, json);
  }

  Future<List<Product>> readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return <Product>[];
      final data = jsonDecode(raw);
      if (data is! List) return <Product>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
    } on FormatException {
      return <Product>[];
    }
  }

  Future<LocalChanges> readChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_changesKey);
      if (raw == null || raw.isEmpty) return LocalChanges();
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) return LocalChanges.fromJson(data);
      return LocalChanges();
    } on FormatException {
      return LocalChanges();
    }
  }

  Future<void> saveChanges(LocalChanges changes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_changesKey, jsonEncode(changes.toJson()));
  }

  Future<void> clearChanges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_changesKey);
  }
}
