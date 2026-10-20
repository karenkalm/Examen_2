import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';

/// Fondo con degradado de las pantallas de login y registro.
/// Debe ir como hijo directo de un Stack.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, this.heightFactor = 0.46});

  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * heightFactor;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.brandGradient),
          child: Stack(
            children: [
              Positioned(top: -70, right: -50, child: _Bubble(size: 220)),
              Positioned(bottom: 20, left: -60, child: _Bubble(size: 150)),
              Positioned(top: 110, left: 36, child: _Bubble(size: 26)),
              Positioned(top: 60, right: 90, child: _Bubble(size: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}

/// Logo de la app.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Icon(
        Icons.storefront_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

/// Título y subtítulo blancos sobre el degradado.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta blanca con sombra que contiene el formulario.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardOf(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
        child: child,
      ),
    );
  }
}

/// Mensaje de error dentro del formulario.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra que indica qué tan segura es la contraseña.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  static const List<String> _labels = [
    '',
    'Débil',
    'Regular',
    'Buena',
    'Fuerte',
  ];

  static const List<Color> _colors = [
    Colors.transparent,
    Color(0xFFE5484D),
    Color(0xFFF5A524),
    Color(0xFF7CB342),
    Color(0xFF12A383),
  ];

  @override
  Widget build(BuildContext context) {
    final strength = Validators.passwordStrength(password);
    final outline = AppTheme.outlineOf(context);
    return AnimatedOpacity(
      opacity: password.isEmpty ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
        child: Row(
          children: [
            for (var i = 1; i <= 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: i <= strength ? _colors[strength] : outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            SizedBox(
              width: 56,
              child: Text(
                _labels[strength],
                style: TextStyle(
                  color: _colors[strength],
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
