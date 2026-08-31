import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/producto.dart';
import '../../core/models/rfq.dart';
import '../../core/theme/app_colors.dart';
import '../categorias/categorias_provider.dart';
import '../productos/catalogo_screen.dart';
import '../rfq/rfq_detalle_screen.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/estado_chip.dart';
import '../shared/widgets/producto_card.dart';
import '../shared/widgets/solicitud_card.dart';

/// RF-08: panel del proveedor — sus productos, las RFQ abiertas y el estado
/// de sus ofertas enviadas, todo en una sola pantalla.
class PanelProveedorScreen extends StatefulWidget {
  const PanelProveedorScreen({super.key});

  @override
  State<PanelProveedorScreen> createState() => _PanelProveedorScreenState();
}

class _PanelProveedorScreenState extends State<PanelProveedorScreen> {
  List<Producto> _productos = [];
  List<RfqSolicitud> _rfqsAbiertas = [];
  List<RfqOferta> _misOfertas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<CategoriasProvider>().cargar();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final miPerfil = await Repositories.proveedores.miPerfil();
      final resultados = await Future.wait([
        Repositories.productos.listar(proveedorId: miPerfil.id),
        Repositories.rfq.listarSolicitudes(estado: 'abierta'),
        Repositories.rfq.misOfertas(),
      ]);
      _productos = resultados[0] as List<Producto>;
      _rfqsAbiertas = resultados[1] as List<RfqSolicitud>;
      _misOfertas = resultados[2] as List<RfqOferta>;
    } catch (e) {
      _error = apiErrorMessage(e).contains('no encontrado')
          ? 'Primero completa el perfil de tu empresa en la pestaña Perfil.'
          : apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<CategoriasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Panel')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  icono: Icons.error_outline,
                  mensaje: _error!,
                  accion: OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SectionHeader(
                        titulo: 'Mis productos (${_productos.length})',
                        accion: 'Ver catálogo',
                        onAccion: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const CatalogoScreen()))
                            .then((_) => _cargar()),
                      ),
                      if (_productos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Todavía no publicas productos.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        ..._productos.take(3).map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ProductoCard(producto: p),
                            )),
                      const SizedBox(height: 20),
                      _SectionHeader(titulo: 'Solicitudes abiertas (${_rfqsAbiertas.length})'),
                      if (_rfqsAbiertas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No hay solicitudes abiertas por ahora.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        ..._rfqsAbiertas.take(5).map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SolicitudCard(
                                solicitud: s,
                                categoriaNombre: categorias.nombreDe(s.categoriaId),
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => RfqDetalleScreen(solicitudId: s.id)))
                                    .then((_) => _cargar()),
                              ),
                            )),
                      const SizedBox(height: 20),
                      _SectionHeader(titulo: 'Mis ofertas enviadas (${_misOfertas.length})'),
                      if (_misOfertas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Aún no envías ofertas.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        ..._misOfertas.map((o) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text('C\$${o.precioOfertado.toStringAsFixed(2)}'),
                                subtitle: o.tiempoEntregaDias != null ? Text('Entrega en ${o.tiempoEntregaDias} días') : null,
                                trailing: EstadoChip(o.estado),
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => RfqDetalleScreen(solicitudId: o.solicitudId)))
                                    .then((_) => _cargar()),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.titulo, this.accion, this.onAccion});

  final String titulo;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        if (accion != null) TextButton(onPressed: onAccion, child: Text(accion!)),
      ],
    );
  }
}
