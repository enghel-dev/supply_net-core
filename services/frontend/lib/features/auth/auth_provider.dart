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

  /// Se marca en `registro()` cuando el rol elegido es "proveedor", para
  /// que `HomeScreen` abra directo la pestaña de perfil (formulario de
  /// creación) en vez del panel — un proveedor recién creado no tiene nada
  /// que mostrar en el panel todavía. Se consume una sola vez (ver
  /// `HomeScreen.initState`).
  bool proveedorNuevo = false;

  /// Se llama una vez al arrancar la app para restaurar la sesión guardada
  /// en `TokenStorage`, si el JWT todavía no expiró.
  ///
  /// La lectura del token es casi instantánea, así que el splash (con el
  /// logo y el aviso de que la app se hizo con ayuda de IA) apenas se
  /// alcanzaba a ver — se fuerza un mínimo de tiempo en pantalla acá en
  /// vez de en la UI, para no acoplar el router a este detalle.
  ///
  /// `flutter_secure_storage` en web depende de WebCrypto/IndexedDB del
  /// navegador; si esa lectura se cuelga (storage corrupto, modo privado,
  /// etc.) la app se queda pegada en el splash para siempre porque
  /// `status` nunca sale de `desconocido` — el timeout evita eso tratando
  /// un storage que no responde como "sin sesión".
  Future<void> restaurarSesion() async {
    final resultados = await Future.wait([
      TokenStorage.instance.read().timeout(
            const Duration(seconds: 4),
            onTimeout: () => null,
          ),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);
    final token = resultados[0] as String?;
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
  }) async {
    final ok = await _ejecutarAuth(
      () => Repositories.auth.registro(
        nombre: nombre,
        email: email,
        password: password,
        rol: rol,
        telefono: telefono,
      ),
    );
    if (ok && rol == 'proveedor') proveedorNuevo = true;
    return ok;
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
