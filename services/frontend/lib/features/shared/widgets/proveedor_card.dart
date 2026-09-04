import 'package:flutter/material.dart';

import '../../../core/models/proveedor.dart';
import '../../../core/theme/app_colors.dart';
import 'badge_verificado.dart';

class ProveedorCard extends StatelessWidget {
  const ProveedorCard({super.key, required this.proveedor, required this.onTap});

  final Proveedor proveedor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  proveedor.nombreEmpresa.isNotEmpty ? proveedor.nombreEmpresa[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            proveedor.nombreEmpresa,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BadgeVerificado(verificado: proveedor.verificado, compacto: true),
                      ],
                    ),
                    if (proveedor.direccion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        proveedor.direccion!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (proveedor.distanciaKm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${proveedor.distanciaKm!.toStringAsFixed(1)} km de distancia',
                        style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
