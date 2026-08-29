class Proveedor {
  Proveedor({
    required this.id,
    required this.usuarioId,
    required this.nombreEmpresa,
    this.descripcion,
    this.direccion,
    this.latitud,
    this.longitud,
    this.telefonoContacto,
    required this.verificado,
    this.distanciaKm,
  });

  final String id;
  final String usuarioId;
  final String nombreEmpresa;
  final String? descripcion;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final String? telefonoContacto;
  final bool verificado;

  /// Solo viene poblado en los resultados de `GET /proveedores` (búsqueda
  /// geolocalizada, RF-04) — null en `GET /proveedores/{id}` o `/me`.
  final double? distanciaKm;

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
        id: json['id'] as String,
        usuarioId: json['usuario_id'] as String,
        nombreEmpresa: json['nombre_empresa'] as String,
        descripcion: json['descripcion'] as String?,
        direccion: json['direccion'] as String?,
        latitud: (json['latitud'] as num?)?.toDouble(),
        longitud: (json['longitud'] as num?)?.toDouble(),
        telefonoContacto: json['telefono_contacto'] as String?,
        verificado: json['verificado'] as bool,
        distanciaKm: (json['distancia_km'] as num?)?.toDouble(),
      );
}
