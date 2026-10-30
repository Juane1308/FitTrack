import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/app_models.dart';
import 'exercise_repository.dart';

class TrainingRepository {
  TrainingRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<List<WorkoutDay>> fetchWeek(String token) async {
    final response = await _client.get(Uri.parse('$_baseUrl/training/week'), headers: _headers(token)).timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! Map<String, dynamic> || data['days'] is! List) return const [];
    return (data['days'] as List).whereType<Map<String, dynamic>>().map(_fromJson).toList(growable: false);
  }

  Future<List<WorkoutDay>> completeDay(String token, String date, bool completed) async {
    final response = await _client.patch(Uri.parse('$_baseUrl/training/week/$date'), headers: _headers(token), body: jsonEncode({'completed': completed})).timeout(const Duration(seconds: 20));
    _ensureSuccess(response);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! Map<String, dynamic> || data['days'] is! List) return const [];
    return (data['days'] as List).whereType<Map<String, dynamic>>().map(_fromJson).toList(growable: false);
  }

  Future<void> recordActivity({
    required String token,
    required String routineName,
    required int durationSeconds,
    required String performedOn,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/training/activities'),
      headers: _headers(token),
      body: jsonEncode({
        'routineName': routineName,
        'durationSeconds': durationSeconds,
        'performedOn': performedOn,
      }),
    ).timeout(const Duration(seconds: 20));
    _ensureSuccess(response);
  }

  WorkoutDay _fromJson(Map<String, dynamic> data) {
    final rawExercises = data['exercises'];
    final exercises = rawExercises is List
        ? rawExercises.whereType<Map<String, dynamic>>().map(_exerciseFromJson).toList(growable: false)
        : const <Exercise>[];
    return WorkoutDay(
      date: data['date'] as String? ?? '',
      dayLabel: data['dayLabel'] as String? ?? '',
      muscleGroup: data['muscleGroup'] as String? ?? '',
      title: data['title'] as String? ?? 'Entrenamiento',
      durationMinutes: data['durationMinutes'] is num ? (data['durationMinutes'] as num).toInt() : 45,
      completed: data['completed'] as bool? ?? false,
      exercises: exercises,
    );
  }

  Exercise _exerciseFromJson(Map<String, dynamic> data) => Exercise(
    slug: data['slug'] as String? ?? '',
    name: ExerciseRepository.spanishName(data['name'] as String? ?? 'Ejercicio'),
    technique: data['focus'] as String? ?? 'Técnica y movimiento seguro.',
    sets: data['sets'] is num ? (data['sets'] as num).toInt() : 3,
    repetitions: 10,
    primaryMuscle: data['primaryMuscle'] as String? ?? '',
    muscleCategory: data['muscleCategory'] as String? ?? 'general',
    level: data['level'] as String? ?? 'intermediate',
    recommendedRepetitions: data['repetitions'] as String? ?? '8-12',
    recommendationFocus: data['focus'] as String? ?? 'Técnica y movimiento seguro.',
    imageUrl: data['imageUrl'] as String?,
    instructions: data['instructions'] is List
        ? (data['instructions'] as List).map((item) => item.toString()).toList(growable: false)
        : const [],
    description: data['description'] as String? ?? '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo cargar la rutina semanal.');
    }
  }
}
