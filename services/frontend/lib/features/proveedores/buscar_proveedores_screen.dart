import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/proveedor_card.dart';
import 'proveedores_provider.dart';

class BuscarProveedoresScreen extends StatefulWidget {
  const BuscarProveedoresScreen({super.key});

  @override
  State<BuscarProveedoresScreen> createState() => _BuscarProveedoresScreenState();
}

class _BuscarProveedoresScreenState extends State<BuscarProveedoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedoresProvider>().buscar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProveedoresProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar proveedores')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Radio: ${provider.radioKm.toStringAsFixed(0)} km',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Slider(
                    value: provider.radioKm,
                    min: 1,
                    max: 100,
                    onChanged: (v) => context.read<ProveedoresProvider>().actualizarUbicacion(radioKm: v),
                    onChangeEnd: (_) => context.read<ProveedoresProvider>().buscar(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.buscar(),
              child: _buildBody(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ProveedoresProvider provider) {
    if (provider.cargando && provider.resultados.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return EmptyState(
        icono: Icons.wifi_off,
        mensaje: provider.error!,
        accion: OutlinedButton(onPressed: provider.buscar, child: const Text('Reintentar')),
      );
    }
    if (provider.resultados.isEmpty) {
      return const EmptyState(
        icono: Icons.storefront_outlined,
        mensaje: 'No hay proveedores dentro de este radio todavía.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = provider.resultados[i];
        return ProveedorCard(proveedor: p, onTap: () => context.push('/proveedores/${p.id}'));
      },
    );
  }
}
