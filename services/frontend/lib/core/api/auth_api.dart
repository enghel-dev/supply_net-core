import '../models/session.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  Future<Session> registro({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    String? telefono,
  }) async {
    final response = await _client.dio.post('/auth/registro', data: {
      'nombre': nombre,
      'email': email,
      'password': password,
      'rol': rol,
      'telefono': telefono,
    });
    return Session.fromLoginJson(response.data as Map<String, dynamic>);
  }

  Future<Session> login({required String email, required String password}) async {
    final response = await _client.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return Session.fromLoginJson(response.data as Map<String, dynamic>);
  }
}
