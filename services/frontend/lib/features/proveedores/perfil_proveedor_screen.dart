import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/proveedor.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../shared/widgets/badge_verificado.dart';
import '../shared/widgets/primary_button.dart';
import '../shared/widgets/selector_ubicacion.dart';
import '../verificacion/verificacion_card.dart';

/// Perfil de empresa del proveedor. `PUT /proveedores/me` hace upsert (ver
/// `service.upsert_perfil`), así que este mismo formulario sirve tanto para
/// crear el perfil la primera vez como para editarlo.
class PerfilProveedorScreen extends StatefulWidget {
  const PerfilProveedorScreen({super.key});

  @override
  State<PerfilProveedorScreen> createState() => _PerfilProveedorScreenState();
}

class _PerfilProveedorScreenState extends State<PerfilProveedorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  /// Managua — centro por defecto del mapa cuando el proveedor todavía no
  /// marcó su ubicación real.
  static final _managua = ll.LatLng(12.1364, -86.2514);
  ll.LatLng? _ubicacion;

  bool _cargando = true;
  bool _guardando = false;
  bool _verificado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final p = await Repositories.proveedores.miPerfil();
      _rellenar(p);
    } on Object catch (e) {
      // 404 esperable si todavía no existe el perfil (primer login).
      if (!apiErrorMessage(e).toLowerCase().contains('no encontrado')) {
        setState(() => _error = apiErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _rellenar(Proveedor p) {
    _nombreCtrl.text = p.nombreEmpresa;
    _descripcionCtrl.text = p.descripcion ?? '';
    _direccionCtrl.text = p.direccion ?? '';
    _telefonoCtrl.text = p.telefonoContacto ?? '';
    _ubicacion = (p.latitud != null && p.longitud != null) ? ll.LatLng(p.latitud!, p.longitud!) : null;
    _verificado = p.verificado;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final p = await Repositories.proveedores.actualizarMiPerfil(
        nombreEmpresa: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
        telefonoContacto: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
        latitud: _ubicacion?.latitude,
        longitud: _ubicacion?.longitude,
      );
      if (!mounted) return;
      setState(() => _verificado = p.verificado);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil guardado')));
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi empresa'),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: BadgeVerificado(verificado: _verificado)))],
      ),
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
                  decoration: const InputDecoration(labelText: 'Nombre de la empresa'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono de contacto'),
                ),
                const SizedBox(height: 16),
                const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SelectorUbicacion(
                  centro: _ubicacion ?? _managua,
                  onCambiar: (punto) => setState(() => _ubicacion = punto),
                ),
                const SizedBox(height: 4),
                Text(
                  _ubicacion == null
                      ? 'Tocá el mapa para marcar la ubicación de tu empresa.'
                      : 'Lat ${_ubicacion!.latitude.toStringAsFixed(5)} · '
                          'Lng ${_ubicacion!.longitude.toStringAsFixed(5)} — tocá el mapa para ajustarla.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'La ubicación determina qué tan cerca aparecerás en las búsquedas de proveedores cercanos.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                PrimaryButton(label: 'Guardar', cargando: _guardando, onPressed: _guardar),
                const SizedBox(height: 24),
                const VerificacionCard(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
