import '../../repositories/auth_repository.dart';

String authErrorMessage(AuthResultStatus status) {
  return switch (status) {
    AuthResultStatus.emailAlreadyRegistered =>
      'Este correo ya está registrado.',
    AuthResultStatus.invalidCredentials => 'Correo o contraseña incorrectos.',
    AuthResultStatus.inactiveAccount => 'La cuenta no está activa.',
    AuthResultStatus.success => '',
  };
}
