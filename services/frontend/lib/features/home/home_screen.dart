import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/auth_provider.dart';
import '../auth/cuenta_comprador_screen.dart';
import '../panel/panel_proveedor_screen.dart';
import '../productos/catalogo_screen.dart';
import '../proveedores/buscar_proveedores_screen.dart';
import '../proveedores/perfil_proveedor_screen.dart';
import '../rfq/mis_rfq_screen.dart';
import '../shared/widgets/supplynet_logo.dart';

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
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    // Proveedor recién registrado: no tiene nada que mostrar en el panel
    // todavía, así que se abre directo el formulario de perfil (pestaña 2).
    if ((auth.session?.esProveedor ?? false) && auth.proveedorNuevo) {
      _index = 2;
      auth.proveedorNuevo = false;
    }
  }

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
        body: Stack(
          children: [
            Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: SupplyNetLogo(size: 48),
                  ),
                  destinations: destinos
                      .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: IndexedStack(index: _index, children: tabs)),
              ],
            ),
            const Positioned(left: 12, bottom: 12, child: _EsquinaAcciones()),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const _BarraMarca(),
              Expanded(child: IndexedStack(index: _index, children: tabs)),
            ],
          ),
          const Positioned(left: 12, bottom: 12, child: _EsquinaAcciones()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinos,
      ),
    );
  }
}

/// Franja delgada con el logo, arriba de las pestañas — layout móvil
/// (el layout de escritorio ya lleva el logo en la NavigationRail).
class _BarraMarca extends StatelessWidget {
  const _BarraMarca();

  @override
  Widget build(BuildContext context) {
    final esOscuro = context.watch<ThemeProvider>().esOscuro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: esOscuro ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(color: esOscuro ? AppColors.borderDark : AppColors.border),
        ),
      ),
      child: const Row(
        children: [
          SupplyNetLogo(size: 32),
          SizedBox(width: 8),
          Text(
            'SupplyNet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Botones fijos en la esquina inferior izquierda: alternar modo
/// oscuro/claro y cerrar sesión, disponibles desde cualquier pestaña.
class _EsquinaAcciones extends StatelessWidget {
  const _EsquinaAcciones();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final esOscuro = context.watch<ThemeProvider>().esOscuro;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      color: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: esOscuro ? AppColors.borderDark : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: esOscuro ? 'Modo claro' : 'Modo oscuro',
              icon: Icon(esOscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: themeProvider.alternar,
            ),
            const SizedBox(
              height: 24,
              child: VerticalDivider(width: 1),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout, color: AppColors.error),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
      ),
    );
  }
}
