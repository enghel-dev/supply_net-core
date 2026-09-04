import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/rfq.dart';
import '../../../core/theme/app_colors.dart';
import 'estado_chip.dart';

class SolicitudCard extends StatelessWidget {
  const SolicitudCard({super.key, required this.solicitud, required this.categoriaNombre, required this.onTap});

  final RfqSolicitud solicitud;
  final String categoriaNombre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(categoriaNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  EstadoChip(solicitud.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                solicitud.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (solicitud.cantidad != null) ...[
                    const Icon(Icons.numbers, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${solicitud.cantidad}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                  ],
                  if (solicitud.fechaLimite != null) ...[
                    const Icon(Icons.event_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(solicitud.fechaLimite!),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
