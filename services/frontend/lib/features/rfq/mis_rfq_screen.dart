import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/rfq.dart';
import '../categorias/categorias_provider.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/solicitud_card.dart';
import 'publicar_rfq_screen.dart';
import 'rfq_detalle_screen.dart';

/// RF-09: panel del comprador — sus solicitudes publicadas.
class MisRfqScreen extends StatefulWidget {
  const MisRfqScreen({super.key});

  @override
  State<MisRfqScreen> createState() => _MisRfqScreenState();
}

class _MisRfqScreenState extends State<MisRfqScreen> {
  List<RfqSolicitud> _solicitudes = [];
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
      _solicitudes = await Repositories.rfq.listarSolicitudes(soloMias: true);
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _nuevaSolicitud() async {
    final creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PublicarRfqScreen()),
    );
    if (creada == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<CategoriasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis solicitudes')),
      floatingActionButton: FloatingActionButton(onPressed: _nuevaSolicitud, child: const Icon(Icons.add)),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? EmptyState(
                    icono: Icons.error_outline,
                    mensaje: _error!,
                    accion: OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
                  )
                : _solicitudes.isEmpty
                    ? const EmptyState(
                        icono: Icons.request_quote_outlined,
                        mensaje: 'Aún no publicas solicitudes de cotización. Toca + para crear la primera.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _solicitudes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final s = _solicitudes[i];
                          return SolicitudCard(
                            solicitud: s,
                            categoriaNombre: categorias.nombreDe(s.categoriaId),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => RfqDetalleScreen(solicitudId: s.id)),
                              );
                              _cargar();
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
