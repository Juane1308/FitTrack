import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack_app/providers/auth_provider.dart';
import 'package:fittrack_app/repositories/auth_repository.dart';

void main() {
  test('registra un usuario y permite iniciar sesión sin guardar la contraseña original', () async {
    final provider = AuthProvider(repository: MockAuthRepository());

    final registration = await provider.register(
      name: 'Ana',
      email: 'ana@example.com',
      password: 'ClaveSegura123',
    );

    expect(registration.isSuccess, isTrue);
    expect(provider.isAuthenticated, isFalse);

    final invalidLogin = await provider.login(
      email: 'ana@example.com',
      password: 'incorrecta',
    );
    expect(invalidLogin.status, AuthResultStatus.invalidCredentials);

    final validLogin = await provider.login(
      email: 'ana@example.com',
      password: 'ClaveSegura123',
    );
    expect(validLogin.isSuccess, isTrue);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.currentUser?.name, 'Ana');
  });

  test('rechaza correos duplicados en el repositorio mock', () async {
    final repository = MockAuthRepository();

    await repository.register(
      name: 'Ana',
      email: 'ana@example.com',
      password: 'ClaveSegura123',
    );
    final duplicate = await repository.register(
      name: 'Otra Ana',
      email: 'ANA@example.com',
      password: 'OtraClave123',
    );

    expect(duplicate.status, AuthResultStatus.emailAlreadyRegistered);
  });
}
