import '../../repositories/auth_repository.dart';

String authErrorMessage(AuthResultStatus status) {
  return switch (status) {
    AuthResultStatus.emailAlreadyRegistered =>
      'Este correo ya está registrado.',
    AuthResultStatus.invalidCredentials => 'Correo o contraseña incorrectos.',
    AuthResultStatus.inactiveAccount => 'La cuenta no está activa.',
    AuthResultStatus.emailNotVerified => 'Verifica tu correo antes de iniciar sesión.',
    AuthResultStatus.verificationFailed => 'El código no es válido o expiró.',
    AuthResultStatus.termsNotAccepted => 'Debes aceptar los términos y condiciones.',
    AuthResultStatus.networkError => 'No se pudo conectar con FITTRACK. Intenta nuevamente.',
    AuthResultStatus.unknownError => 'Ocurrió un error. Intenta nuevamente.',
    AuthResultStatus.success => '',
  };
}
