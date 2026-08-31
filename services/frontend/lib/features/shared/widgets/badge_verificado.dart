import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class BadgeVerificado extends StatelessWidget {
  const BadgeVerificado({super.key, required this.verificado, this.compacto = false});

  final bool verificado;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final color = verificado ? AppColors.success : AppColors.textSecondary;
    final texto = verificado ? 'Verificado' : 'Sin verificar';
    final icono = verificado ? Icons.verified : Icons.hourglass_empty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacto ? 8 : 10, vertical: compacto ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: compacto ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: compacto ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
