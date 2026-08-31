import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/rfq.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../categorias/categorias_provider.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/estado_chip.dart';
import 'responder_oferta_screen.dart';

/// RF-06/RF-09: detalle de una solicitud. El contenido cambia según el rol:
/// el comprador dueño ve todas las ofertas y puede aceptar/rechazar o cerrar
/// la solicitud; el proveedor ve si ya ofertó (`GET /rfq/solicitudes/{id}/ofertas`
/// es solo del comprador dueño, así que el proveedor se apoya en `mis-ofertas`).
class RfqDetalleScreen extends StatefulWidget {
  const RfqDetalleScreen({super.key, required this.solicitudId});

  final String solicitudId;

  @override
  State<RfqDetalleScreen> createState() => _RfqDetalleScreenState();
}

class _RfqDetalleScreenState extends State<RfqDetalleScreen> {
  RfqSolicitud? _solicitud;
  List<RfqOferta> _ofertas = [];
  RfqOferta? _miOferta;
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
    final esComprador = context.read<AuthProvider>().session?.esComprador ?? false;
    try {
      _solicitud = await Repositories.rfq.obtenerSolicitud(widget.solicitudId);
      if (esComprador) {
        _ofertas = await Repositories.rfq.listarOfertasDeSolicitud(widget.solicitudId);
      } else {
        final mias = await Repositories.rfq.misOfertas();
        _miOferta = mias.where((o) => o.solicitudId == widget.solicitudId).firstOrNull;
      }
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _responderOferta(String ofertaId, String nuevoEstado) async {
    try {
      await Repositories.rfq.responderOferta(ofertaId, nuevoEstado);
      _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _cambiarEstadoSolicitud(String nuevoEstado) async {
    try {
      await Repositories.rfq.cambiarEstadoSolicitud(widget.solicitudId, nuevoEstado);
      _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final categorias = context.watch<CategoriasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de cotización')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _solicitud == null
              ? EmptyState(icono: Icons.error_outline, mensaje: _error ?? 'No encontrada.')
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              categorias.nombreDe(_solicitud!.categoriaId),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ),
                          EstadoChip(_solicitud!.estado),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_solicitud!.descripcion),
                      const SizedBox(height: 8),
                      if (_solicitud!.cantidad != null)
                        Text('Cantidad: ${_solicitud!.cantidad}', style: const TextStyle(color: AppColors.textSecondary)),
                      if (_solicitud!.fechaLimite != null)
                        Text(
                          'Fecha límite: ${DateFormat('dd/MM/yyyy').format(_solicitud!.fechaLimite!)}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 24),
                      if (session?.esComprador ?? false) ..._buildVistaComprador(),
                      if (session?.esProveedor ?? false) ..._buildVistaProveedor(),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildVistaComprador() {
    return [
      Row(
        children: [
          Text('Ofertas recibidas (${_ofertas.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          if (_solicitud!.estado == 'abierta')
            TextButton(
              onPressed: () => _cambiarEstadoSolicitud('cerrada'),
              child: const Text('Cerrar solicitud'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (_ofertas.isEmpty)
        const EmptyState(icono: Icons.inbox_outlined, mensaje: 'Todavía no hay ofertas para esta solicitud.')
      else
        ..._ofertas.map((o) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('C\$${o.precioOfertado.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const Spacer(),
                        EstadoChip(o.estado),
                      ],
                    ),
                    if (o.tiempoEntregaDias != null)
                      Text('Entrega en ${o.tiempoEntregaDias} días', style: const TextStyle(color: AppColors.textSecondary)),
                    if (o.mensaje != null && o.mensaje!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(o.mensaje!),
                    ],
                    if (o.estado == 'pendiente') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _responderOferta(o.id, 'rechazada'),
                              child: const Text('Rechazar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _responderOferta(o.id, 'aceptada'),
                              child: const Text('Aceptar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            )),
    ];
  }

  List<Widget> _buildVistaProveedor() {
    if (_miOferta != null) {
      final o = _miOferta!;
      return [
        const Text('Tu oferta', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('C\$${o.precioOfertado.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    EstadoChip(o.estado),
                  ],
                ),
                if (o.tiempoEntregaDias != null)
                  Text('Entrega en ${o.tiempoEntregaDias} días', style: const TextStyle(color: AppColors.textSecondary)),
                if (o.mensaje != null && o.mensaje!.isNotEmpty) ...[const SizedBox(height: 6), Text(o.mensaje!)],
              ],
            ),
          ),
        ),
      ];
    }
    if (_solicitud!.estado != 'abierta') {
      return [const EmptyState(icono: Icons.lock_clock_outlined, mensaje: 'Esta solicitud ya no acepta ofertas.')];
    }
    return [
      ElevatedButton(
        onPressed: () async {
          final enviada = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => ResponderOfertaScreen(solicitudId: widget.solicitudId)),
          );
          if (enviada == true) _cargar();
        },
        child: const Text('Enviar oferta'),
      ),
    ];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
