import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/registro_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/proveedores/detalle_proveedor_screen.dart';
import '../../features/shared/widgets/supplynet_logo.dart';

/// Guard de sesión + rutas de nivel superior. Los tabs internos (comprador
/// vs proveedor) los maneja `HomeScreen`, no el router — solo se necesita
/// distinguir "hay sesión" / "no hay sesión" acá (RF-01).
class AppRouter {
  AppRouter(this.authProvider);

  final AuthProvider authProvider;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final enAuth = state.matchedLocation == '/login' || state.matchedLocation == '/registro';

      if (status == AuthStatus.desconocido) return null;
      if (status == AuthStatus.noAutenticado) return enAuth ? null : '/login';
      if (status == AuthStatus.autenticado && enAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (context, state) => const RegistroScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            authProvider.status == AuthStatus.autenticado ? const HomeScreen() : const _SplashScreen(),
      ),
      GoRoute(
        // Splash explícito tras un login exitoso (ver LoginScreen), no solo
        // en el arranque en frío — se navega solo a "/" pasado el tiempo.
        path: '/splash',
        builder: (context, state) => const _SplashScreen(autoNavigateAfter: Duration(milliseconds: 1200)),
      ),
      GoRoute(
        path: '/proveedores/:id',
        builder: (context, state) => DetalleProveedorScreen(proveedorId: state.pathParameters['id']!),
      ),
    ],
  );
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen({this.autoNavigateAfter});

  /// Si se da, tras este tiempo navega solo a "/" (uso: ruta `/splash`
  /// después de un login exitoso). En el arranque en frío se omite: ahí el
  /// cambio de pantalla ya lo dispara `AuthProvider.restaurarSesion`.
  final Duration? autoNavigateAfter;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    final espera = widget.autoNavigateAfter;
    if (espera != null) {
      Future.delayed(espera, () {
        if (mounted) context.go('/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: Center(child: SupplyNetLogo(size: 140))),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: Text(
                'Este programa fue creado con ayuda de inteligencia artificial',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
