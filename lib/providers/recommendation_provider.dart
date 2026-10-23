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

  PersonalizedRecommendation? get recommendation => _recommendation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(String? token, {bool refresh = false}) async {
    if (token == null || token.isEmpty || (_isLoading && !refresh)) return;
    if (_recommendation != null && !refresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _recommendation = await _repository.fetch(token, refresh: refresh);
    } catch (_) {
      _errorMessage = 'No se pudieron generar recomendaciones personalizadas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
