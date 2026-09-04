import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/api/api_exception.dart';
import '../../core/api/repositories.dart';
import '../../core/models/proveedor.dart';
import '../../core/theme/app_colors.dart';
import '../shared/widgets/badge_verificado.dart';
import '../shared/widgets/primary_button.dart';
import '../shared/widgets/selector_ubicacion.dart';
import '../verificacion/verificacion_card.dart';

/// Perfil de empresa del proveedor. `PUT /proveedores/me` hace upsert (ver
/// `service.upsert_perfil`), así que este mismo formulario sirve tanto para
/// crear el perfil la primera vez como para editarlo.
///
/// Si el perfil ya existe, la pestaña abre en modo **resumen** (nombre,
/// dirección, teléfono) en vez de tirar el formulario de entrada de una vez
/// — "Editar perfil" lleva al formulario. Si todavía no existe (cuenta de
/// proveedor recién creada), abre directo en modo formulario.
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
  bool _perfilExiste = false;
  bool _modoEdicion = false;
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
      _perfilExiste = true;
    } on Object catch (e) {
      // 404 esperable si todavía no existe el perfil (primer login) — ahí
      // se abre directo el formulario en vez del resumen.
      if (!apiErrorMessage(e).toLowerCase().contains('no encontrado')) {
        setState(() => _error = apiErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
          _modoEdicion = !_perfilExiste;
        });
      }
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
      _rellenar(p);
      setState(() {
        _perfilExiste = true;
        _modoEdicion = false;
      });
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
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8), child: Center(child: BadgeVerificado(verificado: _verificado))),
          if (!_modoEdicion)
            IconButton(
              tooltip: 'Editar perfil',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _modoEdicion = true),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _modoEdicion ? _Formulario(state: this) : _Resumen(state: this),
      ),
    );
  }
}

/// Vista de solo lectura: lo que ve el proveedor apenas entra a la pestaña,
/// si ya llenó su perfil antes.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.state});

  final _PerfilProveedorScreenState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state._nombreCtrl.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (state._descripcionCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(state._descripcionCtrl.text, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 20),
          _FilaResumen(
            icono: Icons.place_outlined,
            etiqueta: 'Dirección',
            valor: state._direccionCtrl.text.isEmpty ? 'Sin especificar' : state._direccionCtrl.text,
          ),
          const SizedBox(height: 14),
          _FilaResumen(
            icono: Icons.call_outlined,
            etiqueta: 'Teléfono de contacto',
            valor: state._telefonoCtrl.text.isEmpty ? 'Sin especificar' : state._telefonoCtrl.text,
          ),
          const SizedBox(height: 24),
          const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectorUbicacion(centro: state._ubicacion ?? _PerfilProveedorScreenState._managua),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Editar perfil',
            onPressed: () => state.setState(() => state._modoEdicion = true),
          ),
          const SizedBox(height: 24),
          const VerificacionCard(),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({required this.icono, required this.etiqueta, required this.valor});

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Formulario de creación/edición — el que ya existía, ahora reusado tanto
/// para el alta inicial como para editar desde el resumen.
class _Formulario extends StatelessWidget {
  const _Formulario({required this.state});

  final _PerfilProveedorScreenState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: state._formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: state._nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de la empresa'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: state._descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: state._direccionCtrl,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: state._telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono de contacto'),
            ),
            const SizedBox(height: 16),
            const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SelectorUbicacion(
              centro: state._ubicacion ?? _PerfilProveedorScreenState._managua,
              onCambiar: (punto) => state.setState(() => state._ubicacion = punto),
            ),
            const SizedBox(height: 4),
            Text(
              state._ubicacion == null
                  ? 'Tocá el mapa para marcar la ubicación de tu empresa, o usá el botón de GPS.'
                  : 'Lat ${state._ubicacion!.latitude.toStringAsFixed(5)} · '
                      'Lng ${state._ubicacion!.longitude.toStringAsFixed(5)} — tocá el mapa o usá el GPS para ajustarla.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'La ubicación determina qué tan cerca aparecerás en las búsquedas de proveedores cercanos.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (state._error != null) ...[
              const SizedBox(height: 12),
              Text(state._error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(label: 'Guardar', cargando: state._guardando, onPressed: state._guardar),
            if (state._perfilExiste) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => state.setState(() => state._modoEdicion = false),
                child: const Text('Cancelar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
