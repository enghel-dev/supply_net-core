import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/session.dart';
import '../../core/storage/token_storage.dart';

enum AuthStatus { desconocido, autenticado, noAutenticado }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.desconocido;
  Session? session;
  String? errorMensaje;
  bool cargando = false;

  /// Se llama una vez al arrancar la app para restaurar la sesión guardada
  /// en `TokenStorage`, si el JWT todavía no expiró.
  Future<void> restaurarSesion() async {
    final token = await TokenStorage.instance.read();
    if (token == null || JwtDecoder.isExpired(token)) {
      await TokenStorage.instance.clear();
      status = AuthStatus.noAutenticado;
      notifyListeners();
      return;
    }
    final payload = JwtDecoder.decode(token);
    session = Session(
      usuarioId: payload['sub'] as String,
      rol: payload['rol'] as String,
      accessToken: token,
    );
    status = AuthStatus.autenticado;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _ejecutarAuth(() => Repositories.auth.login(email: email, password: password));
  }

  Future<bool> registro({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    String? telefono,
  }) {
    return _ejecutarAuth(
      () => Repositories.auth.registro(
        nombre: nombre,
        email: email,
        password: password,
        rol: rol,
        telefono: telefono,
      ),
    );
  }

  Future<bool> _ejecutarAuth(Future<Session> Function() accion) async {
    cargando = true;
    errorMensaje = null;
    notifyListeners();
    try {
      final nuevaSesion = await accion();
      await TokenStorage.instance.save(nuevaSesion.accessToken);
      session = nuevaSesion;
      status = AuthStatus.autenticado;
      return true;
    } on DioException catch (e) {
      errorMensaje = apiErrorMessage(e);
      return false;
    } catch (e) {
      errorMensaje = 'Ocurrió un error inesperado. Intenta de nuevo.';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
    session = null;
    status = AuthStatus.noAutenticado;
    notifyListeners();
  }
}
