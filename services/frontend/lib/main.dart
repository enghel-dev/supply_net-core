import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/categorias/categorias_provider.dart';
import 'features/proveedores/proveedores_provider.dart';

void main() {
  runApp(const SupplyNetApp());
}

class SupplyNetApp extends StatelessWidget {
  const SupplyNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..restaurarSesion()),
        ChangeNotifierProvider(create: (_) => CategoriasProvider()),
        ChangeNotifierProvider(create: (_) => ProveedoresProvider()),
      ],
      child: const _AppRouterHost(),
    );
  }
}

/// Separado del árbol de arriba para poder leer el `AuthProvider` recién
/// creado por el `MultiProvider` y pasárselo al router (ver
/// `core/router/app_router.dart` — necesita la instancia, no el `context`,
/// porque `redirect` corre fuera del árbol de widgets).
class _AppRouterHost extends StatefulWidget {
  const _AppRouterHost();

  @override
  State<_AppRouterHost> createState() => _AppRouterHostState();
}

class _AppRouterHostState extends State<_AppRouterHost> {
  late final GoRouter _router = AppRouter(context.read<AuthProvider>()).router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SupplyNet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
