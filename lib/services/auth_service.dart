import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Error de login o registro con un mensaje listo para mostrar.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Módulo de autenticación (login y registro).
///
/// 1. Usuario de prueba: sus datos están en variables y se comparan
///    directamente con lo que se escribe al presionar "Ingresar".
/// 2. Usuarios registrados: se guardan en el dispositivo con la contraseña
///    cifrada (SHA-256) y se comparan de la misma forma.
class AuthService {
  // ── Usuario de prueba (variables) ─────────────────────────────────
  static const String demoUsername = 'admin';
  static const String demoPassword = 'admin123';
  static const String demoName = 'Administrador';
  static const String demoEmail = 'admin@storehub.app';

  static const String _usersKey = 'auth_users_v1';
  static const String _sessionKey = 'auth_session_v1';

  /// Pequeña pausa para que se vea el indicador de carga del botón.
  static const Duration _feedbackDelay = Duration(milliseconds: 350);

  /// Compara los datos ingresados con las variables y con los usuarios
  /// registrados. Si coinciden, guarda la sesión.
  Future<AppUser> login(String username, String password) async {
    final user = username.trim().toLowerCase();
    await Future<void>.delayed(_feedbackDelay);

    // 1) Comparación con las variables del usuario de prueba.
    if (user == demoUsername && password == demoPassword) {
      await _saveSession(demoUsername);
      return _demoUser;
    }

    // 2) Comparación con los usuarios registrados desde la app.
    final users = await _readUsers();
    final hash = hashPassword(user, password);
    for (final registered in users) {
      if (registered.username == user && registered.passwordHash == hash) {
        await _saveSession(registered.username);
        return registered;
      }
    }

    throw const AuthException('Usuario o contraseña incorrectos');
  }

  /// Registra un usuario nuevo (no inicia sesión automáticamente).
  Future<AppUser> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final user = username.trim().toLowerCase();
    final mail = email.trim().toLowerCase();
    await Future<void>.delayed(_feedbackDelay);

    final users = await _readUsers();
    if (user == demoUsername || users.any((u) => u.username == user)) {
      throw const AuthException('Ese nombre de usuario ya está en uso');
    }
    if (mail == demoEmail || users.any((u) => u.email == mail)) {
      throw const AuthException('Ese correo ya está registrado');
    }

    final newUser = AppUser(
      name: name.trim(),
      username: user,
      email: mail,
      passwordHash: hashPassword(user, password),
      createdAt: DateTime.now(),
    );
    await _saveUsers([...users, newUser]);
    return newUser;
  }

  /// Regresa el usuario con sesión activa o `null` si no hay sesión.
  Future<AppUser?> currentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_sessionKey);
    if (username == null) return null;
    if (username == demoUsername) return _demoUser;

    final users = await _readUsers();
    for (final user in users) {
      if (user.username == username) return user;
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Cifra la contraseña con SHA-256 (usando el usuario como "sal").
  static String hashPassword(String username, String password) {
    final bytes = utf8.encode('${username.trim().toLowerCase()}::$password');
    return sha256.convert(bytes).toString();
  }

  AppUser get _demoUser => AppUser(
        name: demoName,
        username: demoUsername,
        email: demoEmail,
        passwordHash: hashPassword(demoUsername, demoPassword),
        createdAt: DateTime(2026),
        isDemo: true,
      );

  Future<void> _saveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, username);
  }

  Future<List<AppUser>> _readUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return <AppUser>[];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return <AppUser>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(AppUser.fromJson)
          .toList();
    } on FormatException {
      return <AppUser>[];
    }
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, json);
  }
}
