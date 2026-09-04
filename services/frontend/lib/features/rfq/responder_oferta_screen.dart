import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/theme/app_colors.dart';
import '../shared/widgets/primary_button.dart';

/// RF-06: un proveedor responde a una solicitud abierta con precio, tiempo
/// de entrega y mensaje opcional. El backend impone la regla de "una sola
/// oferta por proveedor/solicitud" con un `UNIQUE` — si ya ofertó, el POST
/// devuelve 409 y el mensaje de error se muestra tal cual.
class ResponderOfertaScreen extends StatefulWidget {
  const ResponderOfertaScreen({super.key, required this.solicitudId});

  final String solicitudId;

  @override
  State<ResponderOfertaScreen> createState() => _ResponderOfertaScreenState();
}

class _ResponderOfertaScreenState extends State<ResponderOfertaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _precioCtrl = TextEditingController();
  final _diasCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _precioCtrl.dispose();
    _diasCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await Repositories.rfq.crearOferta(
        solicitudId: widget.solicitudId,
        precioOfertado: double.parse(_precioCtrl.text),
        tiempoEntregaDias: _diasCtrl.text.trim().isEmpty ? null : int.tryParse(_diasCtrl.text.trim()),
        mensaje: _mensajeCtrl.text.trim().isEmpty ? null : _mensajeCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar oferta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _precioCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio ofertado'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? 'Precio inválido' : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diasCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tiempo de entrega (días, opcional)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mensajeCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mensaje (opcional)'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                PrimaryButton(label: 'Enviar oferta', cargando: _enviando, onPressed: _enviar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
