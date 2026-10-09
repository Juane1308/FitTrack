import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/app_models.dart';

enum AuthResultStatus {
  success,
  emailAlreadyRegistered,
  invalidCredentials,
  inactiveAccount,
}

class AuthResult {
  const AuthResult({required this.status, this.user});

  final AuthResultStatus status;
  final AppUser? user;

  bool get isSuccess => status == AuthResultStatus.success;
}

abstract interface class AuthRepository {
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthResult> login({required String email, required String password});

  Future<void> requestPasswordReset(String email);
}

class MockAuthRepository implements AuthRepository {
  final Map<String, _StoredUser> _users = {};

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
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
  Future<void> requestPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // El MOCK no envía correos. Tampoco revela si una dirección existe.
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
