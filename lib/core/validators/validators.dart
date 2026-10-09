abstract final class Validators {
  static String? required(
    String? value, {
    String message = 'Por favor, completa todos los campos.',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(value!.trim())) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value != originalPassword) return 'Las contraseñas no coinciden.';
    return null;
  }
}
