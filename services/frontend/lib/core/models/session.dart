/// Sesión activa, derivada del `TokenOut` que devuelve `/auth/login` y
/// `/auth/registro` (ver `services/backend/app/modules/auth/schemas.py`).
class Session {
  Session({required this.usuarioId, required this.rol, required this.accessToken});

  final String usuarioId;
  final String rol; // comprador | proveedor | admin
  final String accessToken;

  bool get esProveedor => rol == 'proveedor';
  bool get esComprador => rol == 'comprador';

  factory Session.fromLoginJson(Map<String, dynamic> json) => Session(
        usuarioId: json['usuario_id'] as String,
        rol: json['rol'] as String,
        accessToken: json['access_token'] as String,
      );
}
