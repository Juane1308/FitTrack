import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/app_models.dart';

enum AuthResultStatus {
  success,
  emailAlreadyRegistered,
  invalidCredentials,
  inactiveAccount,
  emailNotVerified,
  verificationFailed,
  termsNotAccepted,
  networkError,
  unknownError,
}

class AuthResult {
  const AuthResult({required this.status, this.user, this.message, this.sessionToken});

  final AuthResultStatus status;
  final AppUser? user;
  final String? message;
  final String? sessionToken;

  bool get isSuccess => status == AuthResultStatus.success;
}

abstract interface class AuthRepository {
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    bool acceptTerms = true,
  });

  Future<AuthResult> login({required String email, required String password});

  Future<AuthResult?> restoreSession();

  Future<AuthResult> verifyEmail({required String email, required String code});

  Future<AuthResult> resendVerificationCode({required String email});

  Future<AuthResult> requestPasswordReset(String email);

  Future<void> logout();
}

/// Repositorio local utilizado únicamente por las pruebas automatizadas.
/// La aplicación en producción usa [ApiAuthRepository] contra el backend.
class MockAuthRepository implements AuthRepository {
  final Map<String, _MockStoredUser> _users = {};

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    bool acceptTerms = true,
  }) async {
    if (!acceptTerms) return const AuthResult(status: AuthResultStatus.termsNotAccepted);
    final normalizedEmail = email.trim().toLowerCase();
    if (_users.containsKey(normalizedEmail)) {
      return const AuthResult(status: AuthResultStatus.emailAlreadyRegistered);
    }
    final user = AppUser(name: name.trim(), email: normalizedEmail, goal: 'Definir objetivo');
    _users[normalizedEmail] = _MockStoredUser(user: user, passwordHash: _hashPassword(password));
    return AuthResult(status: AuthResultStatus.success, user: user, sessionToken: 'mock-session');
  }

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    final stored = _users[email.trim().toLowerCase()];
    if (stored == null || stored.passwordHash != _hashPassword(password)) {
      return const AuthResult(status: AuthResultStatus.invalidCredentials);
    }
    return AuthResult(status: AuthResultStatus.success, user: stored.user, sessionToken: 'mock-session');
  }

  @override
  Future<AuthResult?> restoreSession() async => null;

  @override
  Future<AuthResult> verifyEmail({required String email, required String code}) async => const AuthResult(status: AuthResultStatus.success);

  @override
  Future<AuthResult> resendVerificationCode({required String email}) async => const AuthResult(status: AuthResultStatus.success);

  @override
  Future<AuthResult> requestPasswordReset(String email) async => const AuthResult(status: AuthResultStatus.success);

  @override
  Future<void> logout() async {}

  String _hashPassword(String password) => sha256.convert(utf8.encode(password)).toString();
}

class _MockStoredUser {
  const _MockStoredUser({required this.user, required this.passwordHash});

  final AppUser user;
  final String passwordHash;
}
