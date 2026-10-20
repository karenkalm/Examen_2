// Configuración general de la app y de la API.

class AppInfo {
  AppInfo._();

  static const String name = 'StoreHub';
  static const String tagline = 'Tu catálogo de productos, siempre a la mano';
}

class ApiConfig {
  ApiConfig._();

  /// URL base de la API: https://fakestoreapi.com/products/
  static const String baseUrl = 'https://fakestoreapi.com';
  static const String productsPath = '/products';

  /// Tiempo máximo de espera de cada petición.
  static const Duration timeout = Duration(seconds: 15);

  /// `/products` o `/products/{id}`.
  static Uri products([int? id]) {
    final suffix = id == null ? '' : '/$id';
    return Uri.parse('$baseUrl$productsPath$suffix');
  }

  /// Imagen de ejemplo para llenar rápido el formulario.
  static const String sampleImage =
      'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg';
}
