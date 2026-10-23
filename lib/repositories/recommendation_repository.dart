import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/app_models.dart';

class RecommendationRepository {
  RecommendationRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<PersonalizedRecommendation> fetch(String token, {bool refresh = false}) async {
    final uri = Uri.parse('$_baseUrl/recommendations').replace(
      queryParameters: refresh ? {'refresh': 'true'} : null,
    );
    final response = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudieron generar las recomendaciones.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return _fromJson(payload['data'] as Map<String, dynamic>);
  }

  PersonalizedRecommendation _fromJson(Map<String, dynamic> data) {
    final training = data['training'] as Map<String, dynamic>? ?? const {};
    final nutrition = data['nutrition'] as Map<String, dynamic>? ?? const {};
    return PersonalizedRecommendation(
      generatedBy: data['generatedBy'] as String? ?? 'fittrack-safe-fallback',
      trainingTitle: training['title'] as String? ?? 'Rutina recomendada',
      trainingSummary: training['summary'] as String? ?? '',
      trainingGroups: _strings(training['groups']),
      safetyNotes: _strings(training['safetyNotes']),
      nutritionMethod: nutrition['method'] as String? ?? 'Alimentación equilibrada',
      nutritionSummary: nutrition['summary'] as String? ?? '',
      meals: _strings(nutrition['meals']),
      focusFoods: _strings(nutrition['focusFoods']),
    );
  }

  List<String> _strings(dynamic value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];
}
