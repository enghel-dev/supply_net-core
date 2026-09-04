import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/theme/app_colors.dart';

/// Mapa con un marcador para elegir o mostrar una ubicación (lat/lng).
///
/// Si se pasa [onCambiar], el mapa es editable: tocar cualquier punto mueve
/// el marcador ahí, y aparece el botón de "usar mi ubicación" (GPS, previo
/// permiso del usuario). Sin [onCambiar] queda en modo solo-lectura (se
/// puede mover/hacer zoom para explorar, pero no reubicar el marcador).
class SelectorUbicacion extends StatefulWidget {
  const SelectorUbicacion({
    super.key,
    required this.centro,
    this.onCambiar,
    this.zoom = 15,
    this.altura = 260,
  });

  final ll.LatLng centro;
  final ValueChanged<ll.LatLng>? onCambiar;
  final double zoom;
  final double altura;

  bool get _editable => onCambiar != null;

  @override
  State<SelectorUbicacion> createState() => _SelectorUbicacionState();
}

class _SelectorUbicacionState extends State<SelectorUbicacion> {
  static const _zoomMin = 3.0;
  static const _zoomMax = 18.0;

  final _mapController = MapController();
  bool _buscandoGps = false;

  void _zoom(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + delta).clamp(_zoomMin, _zoomMax));
  }

  Future<void> _usarUbicacionGps() async {
    setState(() => _buscandoGps = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _avisar('Activa el GPS/ubicación de tu dispositivo para usar esta opción.');
        return;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        _avisar('SupplyNet necesita permiso de ubicación para hacer esto.');
        return;
      }
      final posicion = await _mejorLecturaGps().timeout(const Duration(seconds: 16));
      final punto = ll.LatLng(posicion.latitude, posicion.longitude);
      widget.onCambiar?.call(punto);
      _mapController.move(punto, 17);
      if (posicion.accuracy > 100) {
        _avisar(
          'Ubicación aproximada (±${posicion.accuracy.round()} m) — es lo más preciso que dio '
          'el GPS/red del dispositivo. Tocá el mapa para ajustar el pin si hace falta.',
        );
      }
    } catch (_) {
      _avisar('No se pudo obtener tu ubicación. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  /// La primera lectura de `getCurrentPosition` suele venir de una
  /// triangulación rápida por red/wifi (poco precisa, a veces con cientos
  /// de metros o más de error) antes de que el GPS real del dispositivo
  /// alcance a fijar señal. Se escuchan varias lecturas durante unos
  /// segundos y se toma la de menor radio de error en vez de la primera.
  Future<Position> _mejorLecturaGps() async {
    const tiempoMax = Duration(seconds: 6);
    const precisionBuena = 15.0; // metros — con esto alcanza, no hace falta seguir esperando

    Position? mejor;
    final listo = Completer<void>();
    final sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0),
    ).listen(
      (posicion) {
        if (mejor == null || posicion.accuracy < mejor!.accuracy) mejor = posicion;
        if (posicion.accuracy <= precisionBuena && !listo.isCompleted) listo.complete();
      },
      onError: (_) {
        if (!listo.isCompleted) listo.complete();
      },
    );

    await listo.future.timeout(tiempoMax, onTimeout: () {});
    await sub.cancel();

    if (mejor != null) return mejor!;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    );
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.altura,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.centro,
                initialZoom: widget.zoom,
                minZoom: _zoomMin,
                maxZoom: _zoomMax,
                onTap: widget._editable ? (_, punto) => widget.onCambiar!(punto) : null,
              ),
              children: [
                TileLayer(
                  // CARTO Voyager (probado antes) empezó a pedir API key en
                  // sus tiles gratis — volvemos a los tiles estándar de
                  // OpenStreetMap, que siguen sin necesitar key.
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.byteflow.supplynet_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.centro,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_pin, color: AppColors.primary, size: 40),
                    ),
                  ],
                ),
                const _AtribucionOsm(),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _ControlesZoom(onAcercar: () => _zoom(1), onAlejar: () => _zoom(-1)),
            ),
            if (widget._editable)
              Positioned(
                bottom: 8,
                right: 8,
                child: _BotonGps(cargando: _buscandoGps, onPressed: _usarUbicacionGps),
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlesZoom extends StatelessWidget {
  const _ControlesZoom({required this.onAcercar, required this.onAlejar});

  final VoidCallback onAcercar;
  final VoidCallback onAlejar;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            color: Colors.black87,
            visualDensity: VisualDensity.compact,
            tooltip: 'Acercar',
            onPressed: onAcercar,
          ),
          const SizedBox(height: 1, child: ColoredBox(color: AppColors.border)),
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            color: Colors.black87,
            visualDensity: VisualDensity.compact,
            tooltip: 'Alejar',
            onPressed: onAlejar,
          ),
        ],
      ),
    );
  }
}

class _BotonGps extends StatelessWidget {
  const _BotonGps({required this.cargando, required this.onPressed});

  final bool cargando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: AppColors.accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: cargando ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.my_location, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _AtribucionOsm extends StatelessWidget {
  const _AtribucionOsm();

  @override
  Widget build(BuildContext context) {
    return const SimpleAttributionWidget(
      source: Text('© OpenStreetMap'),
      backgroundColor: Colors.white70,
    );
  }
}
