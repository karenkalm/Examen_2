import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';
import 'auth/login_screen.dart';
import 'products/products_screen.dart';

/// Decide qué pantalla mostrar según el estado de la sesión.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>(
      (auth) => auth.status,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (status) {
        AuthStatus.checking => const SplashScreen(key: ValueKey('splash')),
        AuthStatus.authenticated =>
          const ProductsScreen(key: ValueKey('products')),
        AuthStatus.unauthenticated =>
          const LoginScreen(key: ValueKey('login')),
      },
    );
  }
}

/// Pantalla de bienvenida mientras se revisa la sesión guardada.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.brandGradient),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(size: 84),
                SizedBox(height: 18),
                Text(
                  AppInfo.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
