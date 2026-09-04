import '../models/producto.dart';
import 'api_client.dart';

class ProductosApi {
  ProductosApi(this._client);
  final ApiClient _client;

  Future<Producto> crear(Producto borrador) async {
    final response = await _client.dio.post('/productos', data: borrador.toCreateJson());
    return Producto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Producto>> listar({int? categoriaId, String? proveedorId}) async {
    final response = await _client.dio.get('/productos', queryParameters: {
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (proveedorId != null) 'proveedor_id': proveedorId,
    });
    return (response.data as List).map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Producto> obtener(String productoId) async {
    final response = await _client.dio.get('/productos/$productoId');
    return Producto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Producto> actualizar(String productoId, Map<String, dynamic> cambios) async {
    final response = await _client.dio.put('/productos/$productoId', data: cambios);
    return Producto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminar(String productoId) => _client.dio.delete('/productos/$productoId');
}
