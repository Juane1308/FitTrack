import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/api_auth_repository.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { loggedOut, loading, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? ApiAuthRepository() {
    initialization = _restoreSession();
  }

  final AuthRepository _repository;
  AuthStatus _status = AuthStatus.loggedOut;
  AppUser? _currentUser;
  String? _sessionToken;
  late final Future<void> initialization;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get sessionToken => _sessionToken;

  Future<void> _restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final result = await _repository.restoreSession();
      if (result?.isSuccess == true) {
        _currentUser = result!.user;
        _sessionToken = result.sessionToken;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.loggedOut;
      }
    } catch (_) {
      _status = AuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    bool acceptTerms = true,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();
    final result = await _repository.register(
      name: name,
      email: email,
      password: password,
      acceptTerms: acceptTerms,
    );
    _status = AuthStatus.loggedOut;
    notifyListeners();
    return result;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();
    final result = await _repository.login(email: email, password: password);
    if (result.isSuccess) {
      _currentUser = result.user;
      _sessionToken = result.sessionToken;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.loggedOut;
    }
    notifyListeners();
    return result;
  }

  Future<AuthResult> verifyEmail({required String email, required String code}) {
    return _repository.verifyEmail(email: email, code: code);
  }

  Future<AuthResult> resendVerificationCode({required String email}) {
    return _repository.resendVerificationCode(email: email);
  }

  Future<AuthResult> requestPasswordReset(String email) {
    return _repository.requestPasswordReset(email);
  }

  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _sessionToken = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }

  void updateGoal(String goal) {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(goal: goal);
    notifyListeners();
  }
}
