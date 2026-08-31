import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/producto.dart';
import '../../core/theme/app_colors.dart';
import '../categorias/categorias_provider.dart';
import '../shared/widgets/primary_button.dart';

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, this.producto});

  /// Si viene null es "crear producto"; si no, se edita este.
  final Producto? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockCtrl;
  int? _categoriaId;
  String _unidad = 'unidad';
  bool _guardando = false;
  String? _error;

  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCtrl = TextEditingController(text: p?.precio.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stockDisponible.toString() ?? '0');
    _categoriaId = p?.categoriaId;
    _unidad = p?.unidadMedida ?? 'unidad';
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CategoriasProvider>().cargar());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _categoriaId == null) {
      if (_categoriaId == null) setState(() => _error = 'Selecciona una categoría.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (_editando) {
        await Repositories.productos.actualizar(widget.producto!.id, {
          'categoria_id': _categoriaId,
          'nombre': _nombreCtrl.text.trim(),
          'descripcion': _descripcionCtrl.text.trim(),
          'precio': double.parse(_precioCtrl.text),
          'unidad_medida': _unidad,
          'stock_disponible': double.parse(_stockCtrl.text),
        });
      } else {
        await Repositories.productos.crear(Producto(
          id: '',
          proveedorId: '',
          categoriaId: _categoriaId!,
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
          precio: double.parse(_precioCtrl.text),
          unidadMedida: _unidad,
          stockDisponible: double.parse(_stockCtrl.text),
          activo: true,
        ));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasProvider = context.watch<CategoriasProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar producto' : 'Nuevo producto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del producto'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _categoriaId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: categoriasProvider.categorias
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoriaId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio'),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return (n == null || n < 0) ? 'Precio inválido' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unidad,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                        items: unidadesMedida.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => _unidad = v ?? _unidad),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Stock disponible'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n < 0) ? 'Stock inválido' : null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                PrimaryButton(label: 'Guardar', cargando: _guardando, onPressed: _guardar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
