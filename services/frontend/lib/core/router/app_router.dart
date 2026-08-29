import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/registro_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/proveedores/detalle_proveedor_screen.dart';
import '../theme/app_colors.dart';

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
        path: '/proveedores/:id',
        builder: (context, state) => DetalleProveedorScreen(proveedorId: state.pathParameters['id']!),
      ),
    ],
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Icon(Icons.hub_outlined, size: 56, color: AppColors.primary),
      ),
    );
  }
}
