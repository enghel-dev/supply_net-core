import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/api/repositories.dart';
import '../../core/models/producto.dart';
import '../../core/models/proveedor.dart';
import '../../core/theme/app_colors.dart';
import '../shared/widgets/badge_verificado.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/producto_card.dart';
import '../shared/widgets/selector_ubicacion.dart';

class DetalleProveedorScreen extends StatefulWidget {
  const DetalleProveedorScreen({super.key, required this.proveedorId});

  final String proveedorId;

  @override
  State<DetalleProveedorScreen> createState() => _DetalleProveedorScreenState();
}

class _DetalleProveedorScreenState extends State<DetalleProveedorScreen> {
  late Future<(Proveedor, List<Producto>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<(Proveedor, List<Producto>)> _cargar() async {
    final proveedor = await Repositories.proveedores.obtenerPorId(widget.proveedorId);
    final productos = await Repositories.productos.listar(proveedorId: widget.proveedorId);
    return (proveedor, productos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del proveedor')),
      body: FutureBuilder<(Proveedor, List<Producto>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const EmptyState(icono: Icons.error_outline, mensaje: 'No se pudo cargar el proveedor.');
          }
          final (proveedor, productos) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      proveedor.nombreEmpresa,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  BadgeVerificado(verificado: proveedor.verificado),
                ],
              ),
              if (proveedor.descripcion != null) ...[
                const SizedBox(height: 8),
                Text(proveedor.descripcion!, style: const TextStyle(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 16),
              if (proveedor.direccion != null) _InfoRow(icono: Icons.place_outlined, texto: proveedor.direccion!),
              if (proveedor.telefonoContacto != null)
                _InfoRow(icono: Icons.call_outlined, texto: proveedor.telefonoContacto!),
              if (proveedor.latitud != null && proveedor.longitud != null) ...[
                const SizedBox(height: 8),
                SelectorUbicacion(centro: ll.LatLng(proveedor.latitud!, proveedor.longitud!)),
              ],
              const SizedBox(height: 24),
              Text('Catálogo (${productos.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              if (productos.isEmpty)
                const EmptyState(icono: Icons.inventory_2_outlined, mensaje: 'Este proveedor aún no publicó productos.')
              else
                ...productos.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProductoCard(producto: p),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
