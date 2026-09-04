import '../models/categoria.dart';
import 'api_client.dart';

class CategoriasApi {
  CategoriasApi(this._client);
  final ApiClient _client;

  Future<List<Categoria>> listar() async {
    final response = await _client.dio.get('/categorias');
    return (response.data as List).map((e) => Categoria.fromJson(e as Map<String, dynamic>)).toList();
  }
}
