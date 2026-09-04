import 'package:dio/dio.dart';

/// Excepción de dominio para errores de la API — envuelve el `detail` que
/// devuelve FastAPI (`{"detail": "..."}`) en los 4xx/5xx.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}

/// `ApiClient`'s interceptor adjunta un `ApiException` en `DioException.error`
/// — este helper lo desenvuelve para mostrar un mensaje legible en la UI,
/// con un fallback genérico si el error no vino de la API (timeout, sin red).
String apiErrorMessage(Object error) {
  if (error is DioException && error.error is ApiException) {
    return (error.error as ApiException).message;
  }
  return 'No se pudo conectar con el servidor. Verifica tu conexión.';
}
