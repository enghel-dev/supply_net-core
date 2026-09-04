import 'package:flutter/material.dart';

/// Isotipo de SupplyNet (badge circular "SUPPLY NET" con camión), extraído
/// del manual de identidad del equipo de diseño. Un solo widget para
/// reusar el logo con tamaño consistente en splash, login y navegación.
class SupplyNetLogo extends StatelessWidget {
  const SupplyNetLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
