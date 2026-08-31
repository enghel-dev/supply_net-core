import '../models/rfq.dart';
import 'api_client.dart';

class RfqApi {
  RfqApi(this._client);
  final ApiClient _client;

  Future<RfqSolicitud> crearSolicitud({
    required int categoriaId,
    required String descripcion,
    double? cantidad,
    DateTime? fechaLimite,
  }) async {
    final response = await _client.dio.post('/rfq/solicitudes', data: {
      'categoria_id': categoriaId,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'fecha_limite': fechaLimite?.toIso8601String(),
    });
    return RfqSolicitud.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RfqSolicitud>> listarSolicitudes({
    int? categoriaId,
    String? estado,
    bool soloMias = false,
  }) async {
    final response = await _client.dio.get('/rfq/solicitudes', queryParameters: {
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (estado != null) 'estado': estado,
      'solo_mias': soloMias,
    });
    return (response.data as List)
        .map((e) => RfqSolicitud.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RfqSolicitud> obtenerSolicitud(String solicitudId) async {
    final response = await _client.dio.get('/rfq/solicitudes/$solicitudId');
    return RfqSolicitud.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RfqSolicitud> cambiarEstadoSolicitud(String solicitudId, String nuevoEstado) async {
    final response = await _client.dio.patch(
      '/rfq/solicitudes/$solicitudId/estado',
      queryParameters: {'nuevo_estado': nuevoEstado},
    );
    return RfqSolicitud.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RfqOferta> crearOferta({
    required String solicitudId,
    required double precioOfertado,
    int? tiempoEntregaDias,
    String? mensaje,
  }) async {
    final response = await _client.dio.post('/rfq/solicitudes/$solicitudId/ofertas', data: {
      'precio_ofertado': precioOfertado,
      'tiempo_entrega_dias': tiempoEntregaDias,
      'mensaje': mensaje,
    });
    return RfqOferta.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RfqOferta>> listarOfertasDeSolicitud(String solicitudId) async {
    final response = await _client.dio.get('/rfq/solicitudes/$solicitudId/ofertas');
    return (response.data as List).map((e) => RfqOferta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RfqOferta>> misOfertas() async {
    final response = await _client.dio.get('/rfq/mis-ofertas');
    return (response.data as List).map((e) => RfqOferta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RfqOferta> responderOferta(String ofertaId, String nuevoEstado) async {
    final response = await _client.dio.patch(
      '/rfq/ofertas/$ofertaId/estado',
      queryParameters: {'nuevo_estado': nuevoEstado},
    );
    return RfqOferta.fromJson(response.data as Map<String, dynamic>);
  }
}
