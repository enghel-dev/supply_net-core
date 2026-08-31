import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/producto.dart';
import '../../../core/theme/app_colors.dart';

final _currency = NumberFormat.currency(locale: 'es_NI', symbol: 'C\$');

class ProductoCard extends StatelessWidget {
  const ProductoCard({super.key, required this.producto, this.onTap, this.trailing});

  final Producto producto;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            producto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!producto.activo)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text('Inactivo', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_currency.format(producto.precio)} / ${producto.unidadMedida} · stock ${producto.stockDisponible.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
