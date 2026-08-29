import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/theme/app_colors.dart';
import '../categorias/categorias_provider.dart';
import '../shared/widgets/primary_button.dart';

/// RF-05: publicar solicitud de cotización múltiple.
class PublicarRfqScreen extends StatefulWidget {
  const PublicarRfqScreen({super.key});

  @override
  State<PublicarRfqScreen> createState() => _PublicarRfqScreenState();
}

class _PublicarRfqScreenState extends State<PublicarRfqScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  int? _categoriaId;
  DateTime? _fechaLimite;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CategoriasProvider>().cargar());
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora.add(const Duration(days: 7)),
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _fechaLimite = fecha);
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      setState(() => _error = 'Selecciona una categoría.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await Repositories.rfq.crearSolicitud(
        categoriaId: _categoriaId!,
        descripcion: _descripcionCtrl.text.trim(),
        cantidad: _cantidadCtrl.text.trim().isEmpty ? null : double.tryParse(_cantidadCtrl.text.trim()),
        fechaLimite: _fechaLimite,
      );
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
      appBar: AppBar(title: const Text('Nueva solicitud de cotización')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _categoriaId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: categoriasProvider.categorias
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoriaId = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción de lo que necesitas'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cantidadCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cantidad (opcional)'),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _elegirFecha,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha límite (opcional)'),
                    child: Text(
                      _fechaLimite == null
                          ? 'Sin fecha límite'
                          : '${_fechaLimite!.day}/${_fechaLimite!.month}/${_fechaLimite!.year}',
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                PrimaryButton(label: 'Publicar solicitud', cargando: _guardando, onPressed: _publicar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
