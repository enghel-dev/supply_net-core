import 'api_client.dart';
import 'auth_api.dart';
import 'categorias_api.dart';
import 'productos_api.dart';
import 'proveedores_api.dart';
import 'rfq_api.dart';
import 'verificaciones_api.dart';

/// Punto único de acceso a los wrappers de la API — evita instanciarlos
/// sueltos por cada provider/screen.
class Repositories {
  Repositories._();

  static final auth = AuthApi(ApiClient.instance);
  static final categorias = CategoriasApi(ApiClient.instance);
  static final proveedores = ProveedoresApi(ApiClient.instance);
  static final productos = ProductosApi(ApiClient.instance);
  static final rfq = RfqApi(ApiClient.instance);
  static final verificaciones = VerificacionesApi(ApiClient.instance);
}
