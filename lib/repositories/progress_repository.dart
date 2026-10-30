import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/app_models.dart';

class ProgressRepository {
  ProgressRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<ProgressData> fetch(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/progress'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 20));
    _ensureSuccess(response);
    return _fromPayload(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ProgressData> addEntry({
    required String token,
    required double weight,
    required double height,
    DateTime? recordedAt,
    double? targetWeight,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/progress/entries'),
      headers: _headers(token),
      body: jsonEncode({
        'weight': weight,
        'height': height,
        'recordedAt': recordedAt?.toIso8601String().substring(0, 10),
        'targetWeight': targetWeight,
      }),
    ).timeout(const Duration(seconds: 20));
    _ensureSuccess(response);
    final refreshed = await fetch(token);
    return refreshed;
  }

  Future<ProgressData> uploadPhoto({
    required String token,
    required Uint8List bytes,
    required String mimeType,
    String fileName = 'progreso.jpg',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/progress/photos'),
      headers: _headers(token),
      body: jsonEncode({
        'imageBase64': base64Encode(bytes),
        'mimeType': mimeType,
        'fileName': fileName,
      }),
    ).timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    return fetch(token);
  }

  ProgressData _fromPayload(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return ProgressData.empty;
    final rawSummary = data['summary'] is Map<String, dynamic>
        ? data['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawEntries = data['entries'] is List ? data['entries'] as List : const [];
    final rawWeekly = data['weekly'] is List ? data['weekly'] as List : const [];
    return ProgressData(
      summary: ProgressSummary(
        currentWeight: _number(rawSummary['currentWeight']),
        initialWeight: _number(rawSummary['initialWeight']),
        weightChange: _number(rawSummary['weightChange']),
        bmi: _number(rawSummary['bmi']),
        completedDays: _int(rawSummary['completedDays']),
        plannedDays: _int(rawSummary['plannedDays']),
        weeklyProgress: _number(rawSummary['weeklyProgress']) ?? 0,
        activeStreak: _int(rawSummary['activeStreak']),
        totalMinutes: _int(rawSummary['totalMinutes']),
        weeklyMinutes: _int(rawSummary['weeklyMinutes']),
        targetWeight: _number(rawSummary['targetWeight']),
        completionPercent: _number(rawSummary['completionPercent']),
      ),
      entries: rawEntries.whereType<Map<String, dynamic>>().map(_entryFromJson).toList(growable: false),
      weekly: rawWeekly.whereType<Map<String, dynamic>>().map(_weeklyFromJson).toList(growable: false),
      photos: (data['photos'] is List ? data['photos'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map(_photoFromJson)
          .toList(growable: false),
      photoEligible: data['photoEligible'] as bool? ?? false,
      photoMessage: data['photoMessage'] as String? ?? 'Completa todos los entrenamientos de la semana para subir tu foto.',
    );
  }

  ProgressEntry _entryFromJson(Map<String, dynamic> data) => ProgressEntry(
    date: data['date'] as String? ?? '',
    weight: _number(data['weight']) ?? 0,
    height: _number(data['height']) ?? 0,
  );

  WeeklyProgressPoint _weeklyFromJson(Map<String, dynamic> data) => WeeklyProgressPoint(
    date: data['date'] as String? ?? '',
    label: data['label'] as String? ?? '',
    completed: data['completed'] as bool? ?? false,
    planned: data['planned'] as bool? ?? false,
    durationMinutes: _int(data['durationMinutes']),
    muscleGroup: data['muscleGroup'] as String? ?? '',
  );

  ProgressPhotoData _photoFromJson(Map<String, dynamic> data) => ProgressPhotoData(
    id: data['id'] as String? ?? '',
    weekStart: data['weekStart'] as String? ?? '',
    capturedAt: DateTime.tryParse(data['capturedAt'] as String? ?? '') ?? DateTime.now(),
    mimeType: data['mimeType'] as String? ?? 'image/jpeg',
    dataUrl: data['dataUrl'] as String?,
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo consultar el progreso.');
    }
  }

  double? _number(dynamic value) => value is num ? value.toDouble() : null;
  int _int(dynamic value) => value is num ? value.toInt() : 0;
}
