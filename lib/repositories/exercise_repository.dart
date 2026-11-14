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
    final uri = Uri.parse('$_baseUrl/exercises')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
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
    final imageUrl = _imageUrl(
      data['images'] ?? data['image'] ?? data['imageUrl'],
    );
    final muscles = data['primaryMuscles'];
    final instructions = data['instructions'];
    final recommendation = data['recommendation'];
    final repetitionRange = recommendation is Map<String, dynamic>
        ? recommendation['repetitions'] as String?
        : null;

    return Exercise(
      slug: data['slug'] as String? ?? '',
      name: spanishName(data['name'] as String? ?? 'Ejercicio'),
      technique: instructions is List && instructions.isNotEmpty
          ? instructions.first.toString()
          : 'Consulta la técnica indicada antes de comenzar.',
      sets: recommendation is Map && recommendation['sets'] is num
          ? (recommendation['sets'] as num).toInt()
          : 3,
      repetitions: 10,
      group: data['group'] as String? ?? '',
      level: _normalizeLevel(data['level'] ?? data['difficulty']),
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

  String? _imageUrl(dynamic value) {
    String? image;
    if (value is String) {
      image = value;
    } else if (value is List) {
      final candidates = value.whereType<String>();
      image = candidates.isEmpty ? null : candidates.first;
    } else if (value is Map) {
      for (final key in const ['female', 'male', 'front', 'back']) {
        final candidate = value[key];
        if (candidate is String && candidate.isNotEmpty) {
          image = candidate;
          break;
        }
      }
    }
    if (image == null || image.isEmpty) return null;
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
    return 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$image';
  }

  String _normalizeLevel(dynamic value) {
    final normalized = value?.toString().toLowerCase() ?? '';
    if (normalized.contains('begin')) {
      return 'beginner';
    }
    if (normalized.contains('expert') || normalized.contains('advanced')) {
      return 'expert';
    }
    return 'intermediate';
  }

  static String spanishName(String value) {
    const translations = <String, String>{
      '3/4 Sit-Up': 'Abdominales parciales',
      '90/90 Hamstring': 'Estiramiento de isquiotibiales 90/90',
      'Barbell Bench Press': 'Press de banca con barra',
      'Bench Press': 'Press de banca',
      'Push Up': 'Flexiones de brazos',
      'Push-Up': 'Flexiones de brazos',
      'Pull Up': 'Dominadas',
      'Pull-Up': 'Dominadas',
      'Squat': 'Sentadilla',
      'Barbell Squat': 'Sentadilla con barra',
      'Dumbbell Lateral Raise': 'Elevación lateral con mancuernas',
      'Plank': 'Plancha',
      'Crunch': 'Abdominal corto',
      'Dumbbell Bicep Curl': 'Curl de bíceps con mancuernas',
      'Triceps Pushdown': 'Extensión de tríceps en polea',
      'Deadlift': 'Peso muerto',
      'Lunge': 'Zancada',
    };
    final exact = translations[value];
    if (exact != null) return exact;
    return value
        .replaceAll('_', ' ')
        .replaceAll('Barbell', 'con barra')
        .replaceAll('Dumbbell', 'con mancuernas')
        .replaceAll('Cable', 'en polea')
        .replaceAll('Machine', 'en máquina')
        .replaceAll('Incline', 'inclinado')
        .replaceAll('Decline', 'declinado')
        .replaceAll('Standing', 'de pie')
        .replaceAll('Seated', 'sentado')
        .replaceAll('Lying', 'acostado')
        .replaceAll('Leg Extension', 'extensión de piernas')
        .replaceAll('Leg Curl', 'curl de piernas')
        .replaceAll('Leg Raise', 'elevación de piernas')
        .replaceAll('Lateral Raise', 'elevación lateral')
        .replaceAll('Front Raise', 'elevación frontal')
        .replaceAll('Rear Delt', 'deltoides posterior')
        .replaceAll('Triceps', 'tríceps')
        .replaceAll('Biceps', 'bíceps')
        .replaceAll('Shoulder', 'hombro')
        .replaceAll('Chest', 'pecho')
        .replaceAll('Squat', 'sentadilla')
        .replaceAll('Deadlift', 'peso muerto')
        .replaceAll('Lunge', 'zancada')
        .replaceAll('Row', 'remo')
        .replaceAll('Crunch', 'abdominal')
        .replaceAll('Plank', 'plancha')
        .replaceAll('Pull Up', 'dominada')
        .replaceAll('Push Up', 'flexión de brazos');
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo cargar el catálogo de ejercicios.');
    }
  }
}
