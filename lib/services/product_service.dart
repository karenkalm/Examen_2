import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/product.dart';
import 'api_exception.dart';

/// Consume la FakeStore API: https://fakestoreapi.com/products/
class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  /// GET /products: obtiene el catálogo completo.
  Future<List<Product>> fetchProducts() async {
    final response = await _send(
      () => _client.get(ApiConfig.products(), headers: _headers),
    );
    final data = _decode(response);
    if (data is! List) {
      throw const ApiException('El servidor envió una respuesta inesperada.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  /// GET /products/{id}: obtiene un producto.
  Future<Product> fetchProduct(int id) async {
    final response = await _send(
      () => _client.get(ApiConfig.products(id), headers: _headers),
    );
    return _parseProduct(_decode(response));
  }

  /// POST /products: crea un producto. La API responde con su nuevo id.
  Future<Product> createProduct(Product product) async {
    final response = await _send(
      () => _client.post(
        ApiConfig.products(),
        headers: _headers,
        body: jsonEncode(product.toApiJson()),
      ),
    );
    return _parseProduct(_decode(response));
  }

  /// PUT /products/{id}: actualiza un producto.
  Future<Product> updateProduct(Product product) async {
    final response = await _send(
      () => _client.put(
        ApiConfig.products(product.id),
        headers: _headers,
        body: jsonEncode(product.toApiJson()),
      ),
    );
    return _parseProduct(_decode(response));
  }

  /// DELETE /products/{id}: elimina un producto.
  Future<void> deleteProduct(int id) async {
    await _send(
      () => _client.delete(ApiConfig.products(id), headers: _headers),
    );
  }

  /// Ejecuta la petición y convierte cualquier falla en un ApiException.
  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(ApiConfig.timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'El servidor respondió con un error (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'El servidor tardó demasiado en responder. Revisa tu conexión.',
        isConnectionError: true,
      );
    } on http.ClientException {
      // Sin internet (SocketException) o el servidor no está disponible.
      throw const ApiException(
        'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.',
        isConnectionError: true,
      );
    } on Exception {
      throw const ApiException(
        'No se pudo conectar con el servidor.',
        isConnectionError: true,
      );
    }
  }

  Object? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ApiException('El servidor envió una respuesta inválida.');
    }
  }

  Product _parseProduct(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException('El servidor envió una respuesta inesperada.');
    }
    return Product.fromJson(data);
  }
}
