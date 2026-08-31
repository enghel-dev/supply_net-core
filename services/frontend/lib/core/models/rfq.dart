class RfqSolicitud {
  RfqSolicitud({
    required this.id,
    required this.compradorId,
    required this.categoriaId,
    required this.descripcion,
    this.cantidad,
    this.fechaLimite,
    required this.estado,
  });

  final String id;
  final String compradorId;
  final int categoriaId;
  final String descripcion;
  final double? cantidad;
  final DateTime? fechaLimite;
  final String estado; // abierta | cerrada | cancelada

  factory RfqSolicitud.fromJson(Map<String, dynamic> json) => RfqSolicitud(
        id: json['id'] as String,
        compradorId: json['comprador_id'] as String,
        categoriaId: json['categoria_id'] as int,
        descripcion: json['descripcion'] as String,
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        fechaLimite:
            json['fecha_limite'] != null ? DateTime.parse(json['fecha_limite'] as String) : null,
        estado: json['estado'] as String,
      );
}

class RfqOferta {
  RfqOferta({
    required this.id,
    required this.solicitudId,
    required this.proveedorId,
    required this.precioOfertado,
    this.tiempoEntregaDias,
    this.mensaje,
    required this.estado,
  });

  final String id;
  final String solicitudId;
  final String proveedorId;
  final double precioOfertado;
  final int? tiempoEntregaDias;
  final String? mensaje;
  final String estado; // pendiente | aceptada | rechazada

  factory RfqOferta.fromJson(Map<String, dynamic> json) => RfqOferta(
        id: json['id'] as String,
        solicitudId: json['solicitud_id'] as String,
        proveedorId: json['proveedor_id'] as String,
        precioOfertado: (json['precio_ofertado'] as num).toDouble(),
        tiempoEntregaDias: json['tiempo_entrega_dias'] as int?,
        mensaje: json['mensaje'] as String?,
        estado: json['estado'] as String,
      );
}
