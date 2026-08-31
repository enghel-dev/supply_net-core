import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Chip de color por estado — cubre los enums `estado_rfq`, `estado_oferta`
/// y `estado_verificacion` del schema, todos con la misma semántica visual
/// (verde = éxito, naranja = pendiente/atención, gris = cerrado/neutral,
/// rojo = rechazado/cancelado).
class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key});

  final String estado;

  static const _colores = {
    'abierta': AppColors.success,
    'aceptada': AppColors.success,
    'aprobado': AppColors.success,
    'pendiente': AppColors.warning,
    'cerrada': AppColors.textSecondary,
    'cancelada': AppColors.error,
    'rechazada': AppColors.error,
    'rechazado': AppColors.error,
  };

  static const _etiquetas = {
    'abierta': 'Abierta',
    'cerrada': 'Cerrada',
    'cancelada': 'Cancelada',
    'pendiente': 'Pendiente',
    'aceptada': 'Aceptada',
    'rechazada': 'Rechazada',
    'aprobado': 'Aprobado',
    'rechazado': 'Rechazado',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colores[estado] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(
        _etiquetas[estado] ?? estado,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
