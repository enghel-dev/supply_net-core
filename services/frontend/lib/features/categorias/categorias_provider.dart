import 'package:flutter/foundation.dart';

import '../../core/api/repositories.dart';
import '../../core/models/categoria.dart';

/// Cachea `GET /categorias` en memoria — la lista es de catálogo (rara vez
/// cambia), así que no hace falta recargarla en cada pantalla que la usa
/// (form de producto, form de RFQ, filtros de búsqueda).
class CategoriasProvider extends ChangeNotifier {
  List<Categoria> categorias = [];
  bool cargando = false;
  String? error;

  Future<void> cargar({bool forzar = false}) async {
    if (categorias.isNotEmpty && !forzar) return;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      categorias = await Repositories.categorias.listar();
    } catch (e) {
      error = 'No se pudieron cargar las categorías.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  String nombreDe(int categoriaId) {
    final match = categorias.where((c) => c.id == categoriaId);
    return match.isEmpty ? 'Categoría #$categoriaId' : match.first.nombre;
  }
}
