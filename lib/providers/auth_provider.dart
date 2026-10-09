import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { loggedOut, loading, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? MockAuthRepository();

  final AuthRepository _repository;
  AuthStatus _status = AuthStatus.loggedOut;
  AppUser? _currentUser;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();
    final result = await _repository.register(
      name: name,
      email: email,
      password: password,
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
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.loggedOut;
    }
    notifyListeners();
    return result;
  }

  Future<void> requestPasswordReset(String email) {
    return _repository.requestPasswordReset(email);
  }

  void logout() {
    _currentUser = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
