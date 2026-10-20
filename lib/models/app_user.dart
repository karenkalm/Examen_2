// Modelo del usuario que inicia sesión o se registra.

class AppUser {
  const AppUser({
    required this.name,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.isDemo = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      passwordHash: (json['passwordHash'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  final String name;
  final String username;
  final String email;

  /// Contraseña cifrada con SHA-256 (nunca se guarda en texto plano).
  final String passwordHash;
  final DateTime createdAt;

  /// `true` para el usuario de prueba definido en variables.
  final bool isDemo;

  List<String> get _nameParts =>
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

  String get firstName {
    final parts = _nameParts;
    return parts.isEmpty ? username : parts.first;
  }

  String get initials {
    final parts = _nameParts;
    if (parts.isEmpty) {
      return username.isEmpty ? '?' : username[0].toUpperCase();
    }
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'username': username,
        'email': email,
        'passwordHash': passwordHash,
        'createdAt': createdAt.toIso8601String(),
      };
}
