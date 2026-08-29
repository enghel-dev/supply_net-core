import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// URL base del backend FastAPI. Se resuelve en este orden:
/// 1. `--dart-define=API_BASE_URL=...` al compilar/correr (recomendado).
/// 2. Fallback por plataforma: Android emulator usa el alias especial
///    `10.0.2.2` para llegar al `localhost` del host; Windows/web usan
///    `localhost` directo. Ver `services/frontend/README.md`.
const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _apiBaseUrlOverride.isNotEmpty ? _apiBaseUrlOverride : 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(_toApiException(error));
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;

  DioException _toApiException(DioException error) {
    final response = error.response;
    String message = 'No se pudo conectar con el servidor. Verifica tu conexión.';
    if (response != null) {
      final data = response.data;
      if (data is Map && data['detail'] != null) {
        message = data['detail'].toString();
      } else {
        message = 'Error del servidor (${response.statusCode}).';
      }
    }
    return error.copyWith(error: ApiException(response?.statusCode, message));
  }
}
