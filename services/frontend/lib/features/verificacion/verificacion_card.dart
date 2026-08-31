import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// RF-07 (could-have): la subida real del documento todavía no existe en
/// el backend (ver TODO en `verificaciones/router.py`), así que en vez de
/// un formulario a medias se muestra como "próximamente" en el perfil del
/// proveedor — mismo criterio que documenta `docs/requerimientos-funcionales.md`.
class VerificacionCard extends StatelessWidget {
  const VerificacionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, color: AppColors.textSecondary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sello de verificación', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(
                    'Sube tu documento (RUC, registro sanitario o licencia) para que un admin lo revise. Próximamente.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
