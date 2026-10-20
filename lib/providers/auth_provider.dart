import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

/// Estado del módulo de autenticación para toda la app.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  AuthStatus _status = AuthStatus.checking;
  AppUser? _user;
  bool _isBusy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Al abrir la app revisa si ya había una sesión iniciada.
  Future<void> restoreSession() async {
    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 700),
    );
    AppUser? user;
    try {
      user = await _service.currentSession();
    } catch (_) {
      user = null;
    }
    await minimumSplash;
    _user = user;
    _status =
        user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  /// Lanza [AuthException] si el usuario o la contraseña no coinciden.
  Future<void> login(String username, String password) async {
    _setBusy(true);
    try {
      _user = await _service.login(username, password);
      _status = AuthStatus.authenticated;
    } finally {
      _setBusy(false);
    }
  }

  Future<AppUser> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      return await _service.register(
        name: name,
        username: username,
        email: email,
        password: password,
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
