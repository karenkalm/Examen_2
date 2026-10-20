/// Error amigable que se muestra al usuario cuando falla la API.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.isConnectionError = false,
    this.statusCode,
  });

  final String message;

  /// `true` cuando no hay internet o el servidor no respondió.
  final bool isConnectionError;
  final int? statusCode;

  @override
  String toString() => message;
}
