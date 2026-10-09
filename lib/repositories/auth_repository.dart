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

class MockAuthRepository implements AuthRepository {
  final Map<String, _StoredUser> _users = {};

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    bool acceptTerms = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!acceptTerms) {
      return const AuthResult(status: AuthResultStatus.termsNotAccepted);
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (_users.containsKey(normalizedEmail)) {
      return const AuthResult(status: AuthResultStatus.emailAlreadyRegistered);
    }

    _users[normalizedEmail] = _StoredUser(
      user: AppUser(
        name: name.trim(),
        email: normalizedEmail,
        goal: 'Definir objetivo',
      ),
      passwordHash: _hashPassword(password),
      isActive: true,
    );
    return AuthResult(
      status: AuthResultStatus.success,
      user: _users[normalizedEmail]!.user,
    );
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final storedUser = _users[email.trim().toLowerCase()];
    if (storedUser == null ||
        storedUser.passwordHash != _hashPassword(password)) {
      return const AuthResult(status: AuthResultStatus.invalidCredentials);
    }
    if (!storedUser.isActive) {
      return const AuthResult(status: AuthResultStatus.inactiveAccount);
    }
    return AuthResult(status: AuthResultStatus.success, user: storedUser.user);
  }

  @override
  Future<AuthResult?> restoreSession() async => null;

  @override
  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const AuthResult(status: AuthResultStatus.success);
  }

  @override
  Future<AuthResult> resendVerificationCode({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const AuthResult(status: AuthResultStatus.success);
  }

  @override
  Future<AuthResult> requestPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // El MOCK no envía correos. Tampoco revela si una dirección existe.
    return const AuthResult(status: AuthResultStatus.success);
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}

class _StoredUser {
  const _StoredUser({
    required this.user,
    required this.passwordHash,
    required this.isActive,
  });

  final AppUser user;
  final String passwordHash;
  final bool isActive;
}
