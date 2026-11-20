import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/recommendation_repository.dart';

class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({RecommendationRepository? repository})
    : _repository = repository ?? RecommendationRepository();

  final RecommendationRepository _repository;
  PersonalizedRecommendation? _recommendation;
  bool _isLoading = false;
  String? _errorMessage;
  int _userDataGeneration = 0;

  PersonalizedRecommendation? get recommendation => _recommendation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearUserData() {
    _userDataGeneration++;
    _recommendation = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> load(String? token, {bool refresh = false}) async {
    if (token == null || token.isEmpty || (_isLoading && !refresh)) return;
    if (_recommendation != null && !refresh) return;
    final requestGeneration = _userDataGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final recommendation = await _repository.fetch(token, refresh: refresh);
      if (requestGeneration == _userDataGeneration) {
        _recommendation = recommendation;
      }
    } catch (_) {
      if (requestGeneration == _userDataGeneration) {
        _errorMessage = 'No se pudieron generar recomendaciones personalizadas.';
      }
    } finally {
      if (requestGeneration == _userDataGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
