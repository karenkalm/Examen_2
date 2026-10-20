import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StoreHubApp());
}

class StoreHubApp extends StatelessWidget {
  const StoreHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Módulo de autenticación: revisa si ya hay una sesión guardada.
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService())..restoreSession(),
        ),
        // Catálogo de productos (FakeStore API).
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: AppInfo.name,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}
