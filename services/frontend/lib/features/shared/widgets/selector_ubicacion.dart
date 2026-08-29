import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/theme/app_colors.dart';

/// Mapa con un marcador para elegir o mostrar una ubicación (lat/lng).
///
/// Si se pasa [onCambiar], el mapa es editable: tocar cualquier punto mueve
/// el marcador ahí. Sin [onCambiar] queda en modo solo-lectura (se puede
/// mover/hacer zoom para explorar, pero no se puede reubicar el marcador).
class SelectorUbicacion extends StatelessWidget {
  const SelectorUbicacion({
    super.key,
    required this.centro,
    this.onCambiar,
    this.zoom = 14,
    this.altura = 220,
  });

  final ll.LatLng centro;
  final ValueChanged<ll.LatLng>? onCambiar;
  final double zoom;
  final double altura;

  bool get _editable => onCambiar != null;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: altura,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: centro,
            initialZoom: zoom,
            onTap: _editable ? (_, punto) => onCambiar!(punto) : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.byteflow.supplynet_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: centro,
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
