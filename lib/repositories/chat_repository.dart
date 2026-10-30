import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/app_models.dart';

class ChatRepository {
  ChatRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<ChatResponse> sendMessage({
    required String token,
    required String message,
    required String section,
    String? goal,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
        'section': section,
        if (goal != null && goal.trim().isNotEmpty) 'goal': goal,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('El asistente no pudo responder en este momento.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    final text = data is Map<String, dynamic> ? data['message'] : null;
    if (text is! String || text.trim().isEmpty) {
      throw const FormatException('Respuesta vacía del asistente.');
    }
    final exercisePayload = data is Map<String, dynamic> ? data['exercises'] : null;
    final exercises = exercisePayload is List
        ? exercisePayload
            .whereType<Map<String, dynamic>>()
            .map(_exerciseFromJson)
            .toList(growable: false)
        : const <Exercise>[];
    return ChatResponse(message: text, exercises: exercises);
  }

  Exercise _exerciseFromJson(Map<String, dynamic> data) {
    final instructions = data['instructions'] is List
        ? (data['instructions'] as List)
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final repetitions = data['repetitions']?.toString() ?? '8-12';
    final primaryMuscles = data['primaryMuscles'] is List
        ? (data['primaryMuscles'] as List)
            .map((item) => item.toString())
            .toList(growable: false)
        : const <String>[];
    final rawImage = data['imageUrl']?.toString();

    return Exercise(
      slug: data['slug']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Ejercicio',
      technique: data['technique']?.toString().trim().isNotEmpty == true
          ? data['technique'].toString()
          : instructions.isNotEmpty
          ? instructions.first
          : 'Consulta la técnica antes de comenzar.',
      sets: data['sets'] is num ? (data['sets'] as num).toInt() : 3,
      repetitions: _firstRepetition(repetitions),
      group: data['muscleCategory']?.toString() ?? '',
      muscleCategory: data['muscleCategory']?.toString() ?? 'general',
      primaryMuscle: primaryMuscles.isNotEmpty ? primaryMuscles.first : '',
      recommendedRepetitions: repetitions,
      recommendationFocus:
          data['recommendationFocus']?.toString() ?? 'técnica y movimiento seguro',
      imageUrl: _resolveImageUrl(rawImage),
      instructions: instructions,
      description: data['description']?.toString() ?? '',
    );
  }

  int _firstRepetition(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return int.tryParse(match?.group(0) ?? '') ?? 10;
  }

  String? _resolveImageUrl(String? image) {
    if (image == null || image.trim().isEmpty) return null;
    if (image.startsWith('http://') || image.startsWith('https://')) return image;
    if (image.startsWith('/')) {
      final root = _baseUrl.replaceFirst(RegExp(r'/api$'), '');
      return '$root$image';
    }
    return 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$image';
  }
}

class ChatResponse {
  const ChatResponse({required this.message, required this.exercises});

  final String message;
  final List<Exercise> exercises;
}
