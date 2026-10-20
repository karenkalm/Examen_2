import 'package:flutter/material.dart';

/// Categorías de la FakeStore API con su nombre en español e ícono.
class ProductCategories {
  ProductCategories._();

  static const List<String> defaults = [
    'electronics',
    'jewelery',
    "men's clothing",
    "women's clothing",
  ];

  static String label(String category) {
    return switch (category.toLowerCase()) {
      'electronics' => 'Electrónica',
      'jewelery' => 'Joyería',
      "men's clothing" => 'Ropa de hombre',
      "women's clothing" => 'Ropa de mujer',
      '' => 'Sin categoría',
      _ => '${category[0].toUpperCase()}${category.substring(1)}',
    };
  }

  static IconData icon(String category) {
    return switch (category.toLowerCase()) {
      'electronics' => Icons.devices_rounded,
      'jewelery' => Icons.diamond_outlined,
      "men's clothing" => Icons.man_rounded,
      "women's clothing" => Icons.woman_rounded,
      _ => Icons.sell_outlined,
    };
  }
}
