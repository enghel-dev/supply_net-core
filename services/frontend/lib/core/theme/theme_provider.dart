import 'package:flutter/material.dart';

/// Estado del modo claro/oscuro de la app, controlado desde el botón en la
/// esquina inferior izquierda (ver `HomeScreen`). Vive solo en memoria — se
/// reinicia a claro en cada arranque, no se persiste.
class ThemeProvider extends ChangeNotifier {
  ThemeMode modo = ThemeMode.light;

  bool get esOscuro => modo == ThemeMode.dark;

  void alternar() {
    modo = esOscuro ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
