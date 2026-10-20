// Validaciones de todos los formularios (login, registro y productos).

class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _usernameRegExp = RegExp(r'^[a-zA-Z0-9_.]+$');
  static final RegExp _priceRegExp = RegExp(r'^\d+([.,]\d{1,2})?$');
  static final RegExp _hasLetter = RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]');
  static final RegExp _hasDigit = RegExp(r'\d');

  // ── Login ──────────────────────────────────────────────────────────

  /// Restricción de la práctica: usuario y contraseña no pueden ir vacíos.
  static String? requiredField(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  // ── Registro ───────────────────────────────────────────────────────

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu nombre';
    if (text.length < 3) return 'El nombre debe tener al menos 3 letras';
    if (_hasDigit.hasMatch(text)) return 'El nombre no debe llevar números';
    return null;
  }

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa un nombre de usuario';
    if (text.length < 4) return 'Mínimo 4 caracteres';
    if (text.length > 20) return 'Máximo 20 caracteres';
    if (!_usernameRegExp.hasMatch(text)) {
      return 'Sólo letras, números, punto y guion bajo (sin espacios)';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo';
    if (!_emailRegExp.hasMatch(text)) return 'Ingresa un correo válido';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Ingresa una contraseña';
    if (text.length < 6) return 'Mínimo 6 caracteres';
    if (!_hasLetter.hasMatch(text) || !_hasDigit.hasMatch(text)) {
      return 'Combina letras y números';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  /// Nivel de seguridad de la contraseña, de 0 (vacía) a 4 (fuerte).
  static int passwordStrength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (_hasLetter.hasMatch(value) && _hasDigit.hasMatch(value)) score++;
    final mixedCase = RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[A-Z]').hasMatch(value);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(value);
    if (mixedCase || hasSymbol) score++;
    return score == 0 ? 1 : score;
  }

  // ── Productos ──────────────────────────────────────────────────────

  static String? productTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa el nombre del producto';
    if (text.length < 3) return 'Mínimo 3 caracteres';
    if (text.length > 80) return 'Máximo 80 caracteres';
    return null;
  }

  static String? price(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Ingresa el precio';
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null) return 'Ingresa un número válido';
    if (!_priceRegExp.hasMatch(text)) return 'Usa máximo 2 decimales';
    if (parsed <= 0) return 'El precio debe ser mayor a 0';
    if (parsed > 100000) return 'El precio no puede pasar de 100,000';
    return null;
  }

  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa una descripción';
    if (text.length < 10) return 'Describe el producto (mínimo 10 caracteres)';
    if (text.length > 600) return 'Máximo 600 caracteres';
    return null;
  }

  static String? category(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Selecciona una categoría';
    }
    return null;
  }

  static String? imageUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa la URL de la imagen';
    final uri = Uri.tryParse(text);
    final validScheme =
        uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    if (!validScheme || uri.host.isEmpty) {
      return 'Ingresa una URL válida (http o https)';
    }
    return null;
  }
}
