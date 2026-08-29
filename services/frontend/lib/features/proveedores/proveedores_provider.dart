import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/proveedor.dart';

/// RF-04: sin plugin de geolocalización nativo (para no arriesgar el build
/// de Windows/Android sin poder compilar y probarlo en este entorno) — el
/// comprador ingresa o ajusta su ubicación a mano, con Managua como default.
class ProveedoresProvider extends ChangeNotifier {
  double lat = 12.1364;
  double lng = -86.2514;
  double radioKm = 10;

  List<Proveedor> resultados = [];
  bool cargando = false;
  String? error;

  Future<void> buscar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      resultados = await Repositories.proveedores.buscarCercanos(lat: lat, lng: lng, radioKm: radioKm);
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void actualizarUbicacion({double? lat, double? lng, double? radioKm}) {
    if (lat != null) this.lat = lat;
    if (lng != null) this.lng = lng;
    if (radioKm != null) this.radioKm = radioKm;
    notifyListeners();
  }
}
