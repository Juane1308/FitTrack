import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_config.dart';
import '../models/app_models.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;
  String? _sessionToken;
  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _storage =>
      _preferences ??= SharedPreferencesAsync();

  static const _sessionTokenKey = 'fittrack.session_token';
  static const _sessionNameKey = 'fittrack.session_name';
  static const _sessionEmailKey = 'fittrack.session_email';

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    bool acceptTerms = true,
  }) async {
    try {
      final response = await _post('/auth/register', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'confirmPassword': password,
        'acceptTerms': acceptTerms,
      });
      return _resultFromResponse(response);
    } catch (_) {
      return _networkError();
    }
  }

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final response = await _post('/auth/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      final result = _resultFromResponse(response);
      if (result.isSuccess) {
        _sessionToken = result.sessionToken;
        await _persistSession(result);
      }
      return result;
    } catch (_) {
      return _networkError();
    }
  }

  @override
  Future<AuthResult?> restoreSession() async {
    final token = await _storage.getString(_sessionTokenKey);
    if (token == null || token.isEmpty) return null;

    _sessionToken = token;
    return AuthResult(
      status: AuthResultStatus.success,
      user: AppUser(
        name: await _storage.getString(_sessionNameKey) ?? 'Usuario FITTRACK',
        email: await _storage.getString(_sessionEmailKey) ?? '',
        goal: 'Definir objetivo',
      ),
      sessionToken: token,
    );
  }

  @override
  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    try {
      final response = await _post('/auth/verify-email', {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      });
      return _resultFromResponse(response);
    } catch (_) {
      return _networkError();
    }
  }

  @override
  Future<AuthResult> resendVerificationCode({required String email}) async {
    try {
      final response = await _post('/auth/resend-verification', {
        'email': email.trim().toLowerCase(),
      });
      return _resultFromResponse(response);
    } catch (_) {
      return _networkError();
    }
  }

  @override
  Future<AuthResult> requestPasswordReset(String email) async {
    try {
      final response = await _post('/auth/password-recovery', {
        'email': email.trim().toLowerCase(),
      });
      return _resultFromResponse(response);
    } catch (_) {
      return _networkError();
    }
  }

  @override
  Future<void> logout() async {
    final token = _sessionToken;
    _sessionToken = null;
    await _storage.remove(_sessionTokenKey);
    await _storage.remove(_sessionNameKey);
    await _storage.remove(_sessionEmailKey);
    if (token == null) return;

    try {
      await _post('/auth/logout', {}, token: token);
    } catch (_) {
      // La sesión local ya se elimina aunque el servidor no responda.
    }
  }

  Future<void> _persistSession(AuthResult result) async {
    final token = result.sessionToken;
    final user = result.user;
    if (token == null || user == null) return;

    await _storage.setString(_sessionTokenKey, token);
    await _storage.setString(_sessionNameKey, user.name);
    await _storage.setString(_sessionEmailKey, user.email);
  }

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final authorizationToken = token ?? _sessionToken;
    if (authorizationToken != null) {
      headers['Authorization'] = 'Bearer $authorizationToken';
    }

    return _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  AuthResult _resultFromResponse(http.Response response) {
    final data = _decode(response.body);
    final message = data['message'] as String?;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final userData = data['user'];
      final sessionToken = data['token'] as String?;
      return AuthResult(
        status: AuthResultStatus.success,
        user: userData is Map<String, dynamic> ? _userFromJson(userData) : null,
        message: message,
        sessionToken: sessionToken,
      );
    }

    final error = data['error'] as String?;
    final status = switch (response.statusCode) {
      401 => AuthResultStatus.invalidCredentials,
      403 when error?.contains('Verifica') == true => AuthResultStatus.emailNotVerified,
      403 => AuthResultStatus.inactiveAccount,
      409 => AuthResultStatus.emailAlreadyRegistered,
      400 when error?.contains('términos') == true => AuthResultStatus.termsNotAccepted,
      400 when error?.contains('código') == true => AuthResultStatus.verificationFailed,
      _ => AuthResultStatus.unknownError,
    };

    return AuthResult(status: status, message: error);
  }

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  AppUser _userFromJson(Map<String, dynamic> data) {
    return AppUser(
      name: data['name'] as String? ?? 'Usuario FITTRACK',
      email: data['email'] as String? ?? '',
      goal: 'Definir objetivo',
    );
  }

  AuthResult _networkError() {
    return const AuthResult(
      status: AuthResultStatus.networkError,
      message: 'No se pudo conectar con FITTRACK. Verifica que el backend esté ejecutándose.',
    );
  }
}
