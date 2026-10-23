import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/app_models.dart';

class ExerciseRepository {
  ExerciseRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<List<Exercise>> fetchExercises({String? group, String? goal}) async {
    final query = <String, String>{};
    if (group != null && group.trim().isNotEmpty) query['group'] = group.trim();
    if (goal != null && goal.trim().isNotEmpty) query['goal'] = goal.trim();
    final uri = Uri.parse('$_baseUrl/exercises').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);
  }

  Future<Exercise> fetchExercise(String slug) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/exercises/${Uri.encodeComponent(slug)}'))
        .timeout(const Duration(seconds: 12));
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de ejercicio inválida.');
    }
    return _fromJson(data);
  }

  Exercise _fromJson(Map<String, dynamic> data) {
    final images = data['images'];
    final imageUrl = images is Map<String, dynamic>
        ? (images['female'] as String? ?? images['male'] as String?)
        : null;
    final muscles = data['primaryMuscles'];
    final instructions = data['instructions'];
    final recommendation = data['recommendation'];
    final repetitionRange = recommendation is Map<String, dynamic>
        ? recommendation['repetitions'] as String?
        : null;

    return Exercise(
      slug: data['slug'] as String? ?? '',
      name: data['name'] as String? ?? 'Ejercicio',
      technique: instructions is List && instructions.isNotEmpty
          ? instructions.first.toString()
          : 'Consulta la técnica indicada antes de comenzar.',
      sets: recommendation is Map && recommendation['sets'] is num
          ? (recommendation['sets'] as num).toInt()
          : 3,
      repetitions: 10,
      group: data['group'] as String? ?? '',
      primaryMuscle: muscles is List && muscles.isNotEmpty
          ? muscles.first.toString()
          : '',
      muscleCategory: data['muscleCategory'] as String? ?? 'general',
      recommendedRepetitions: repetitionRange ?? '8-12',
      recommendationFocus: recommendation is Map<String, dynamic>
          ? recommendation['focus'] as String? ?? 'técnica y movimiento seguro'
          : 'técnica y movimiento seguro',
      imageUrl: imageUrl,
      instructions: instructions is List
          ? instructions.map((item) => item.toString()).toList(growable: false)
          : const [],
      description: data['description'] as String? ?? '',
    );
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo cargar el catálogo de ejercicios.');
    }
  }
}
