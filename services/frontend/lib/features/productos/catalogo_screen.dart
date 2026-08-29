import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/producto.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/producto_card.dart';
import 'producto_form_screen.dart';

/// RF-03: catálogo del proveedor autenticado (crear, editar,
/// activar/desactivar, eliminar). `GET /productos` no filtra por dueño por
/// defecto, así que pedimos el perfil propio primero para tener el
/// `proveedor_id` y filtrar client-side de una la lista completa.
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List<Producto> _productos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final miPerfil = await Repositories.proveedores.miPerfil();
      _productos = await Repositories.productos.listar(proveedorId: miPerfil.id);
    } catch (e) {
      _error = apiErrorMessage(e).contains('no encontrado')
          ? 'Primero completa el perfil de tu empresa en la pestaña Perfil.'
          : apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _alternarActivo(Producto p) async {
    try {
      await Repositories.productos.actualizar(p.id, {'activo': !p.activo});
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  Future<void> _eliminar(Producto p) async {
    try {
      await Repositories.productos.eliminar(p.id);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  Future<void> _abrirFormulario({Producto? producto}) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: producto)),
    );
    if (guardado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi catálogo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(onRefresh: _cargar, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EmptyState(
        icono: Icons.error_outline,
        mensaje: _error!,
        accion: OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
      );
    }
    if (_productos.isEmpty) {
      return const EmptyState(
        icono: Icons.inventory_2_outlined,
        mensaje: 'Todavía no tienes productos. Toca + para agregar el primero.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _productos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = _productos[i];
        return ProductoCard(
          producto: p,
          onTap: () => _abrirFormulario(producto: p),
          trailing: PopupMenuButton<String>(
            onSelected: (accion) {
              if (accion == 'editar') _abrirFormulario(producto: p);
              if (accion == 'alternar') _alternarActivo(p);
              if (accion == 'eliminar') _eliminar(p);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'alternar', child: Text(p.activo ? 'Desactivar' : 'Activar')),
              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        );
      },
    );
  }
}
