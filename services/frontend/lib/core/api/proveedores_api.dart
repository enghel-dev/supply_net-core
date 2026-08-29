import '../models/proveedor.dart';
import 'api_client.dart';

class ProveedoresApi {
  ProveedoresApi(this._client);
  final ApiClient _client;

  Future<Proveedor> actualizarMiPerfil({
    required String nombreEmpresa,
    String? descripcion,
    String? direccion,
    double? latitud,
    double? longitud,
    String? telefonoContacto,
  }) async {
    final response = await _client.dio.put('/proveedores/me', data: {
      'nombre_empresa': nombreEmpresa,
      'descripcion': descripcion,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'telefono_contacto': telefonoContacto,
    });
    return Proveedor.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Proveedor> miPerfil() async {
    final response = await _client.dio.get('/proveedores/me');
    return Proveedor.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Proveedor>> buscarCercanos({
    required double lat,
    required double lng,
    double radioKm = 10,
  }) async {
    final response = await _client.dio.get('/proveedores', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radio_km': radioKm,
    });
    return (response.data as List).map((e) => Proveedor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Proveedor> obtenerPorId(String proveedorId) async {
    final response = await _client.dio.get('/proveedores/$proveedorId');
    return Proveedor.fromJson(response.data as Map<String, dynamic>);
  }
}
