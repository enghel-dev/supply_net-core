import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../auth/cuenta_comprador_screen.dart';
import '../panel/panel_proveedor_screen.dart';
import '../productos/catalogo_screen.dart';
import '../proveedores/buscar_proveedores_screen.dart';
import '../proveedores/perfil_proveedor_screen.dart';
import '../rfq/mis_rfq_screen.dart';

/// Shell con navegación inferior, distinta según el rol de la sesión activa
/// (RF-01: "restringir las acciones disponibles según el rol del usuario").
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final esProveedor = context.watch<AuthProvider>().session?.esProveedor ?? false;

    final tabs = esProveedor
        ? const [PanelProveedorScreen(), CatalogoScreen(), PerfilProveedorScreen()]
        : const [BuscarProveedoresScreen(), MisRfqScreen(), CuentaCompradorScreen()];

    final destinos = esProveedor
        ? const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Panel'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Catálogo'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Buscar'),
            NavigationDestination(icon: Icon(Icons.request_quote_outlined), selectedIcon: Icon(Icons.request_quote), label: 'Mis RFQs'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          ];

    // Ventanas anchas (Windows) usan un rail lateral en vez de la barra
    // inferior — mismos destinos y contenido, solo cambia el layout.
    final anchoVentana = MediaQuery.sizeOf(context).width;
    final esEscritorio = anchoVentana >= 840;

    if (esEscritorio) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: destinos
                  .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: IndexedStack(index: _index, children: tabs)),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinos,
      ),
    );
  }
}
