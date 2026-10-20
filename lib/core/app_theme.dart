import 'package:flutter/material.dart';

/// Paleta y tema visual de la app (Material 3, modo claro y oscuro).
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF0E7C66);
  static const Color brandDark = Color(0xFF0A4F45);
  static const Color star = Color(0xFFF5A524);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14A586), seed, brandDark],
  );

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static Color backgroundFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF0E1416)
          : const Color(0xFFF3F6F5);

  static Color cardFor(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF172124) : Colors.white;

  static Color outlineFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF26333A)
          : const Color(0xFFE2E8E6);

  static Color fieldFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF1B272B)
          : const Color(0xFFF7FAF9);

  /// Atajos para usar dentro de los widgets.
  static Color cardOf(BuildContext context) =>
      cardFor(Theme.of(context).brightness);
  static Color outlineOf(BuildContext context) =>
      outlineFor(Theme.of(context).brightness);
  static Color fieldOf(BuildContext context) =>
      fieldFor(Theme.of(context).brightness);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final background = backgroundFor(brightness);
    final outline = outlineFor(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardFor(brightness),
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, space: 1),
    );
  }
}
