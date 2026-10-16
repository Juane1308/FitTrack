import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import '../models/app_models.dart';

class ProfileRepository {
  ProfileRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<UserProfile?> fetchProfile(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/profile'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 12));
    _ensureSuccess(response);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    return data is Map<String, dynamic> ? _fromJson(data) : null;
  }

  Future<UserProfile> saveProfile(String token, UserProfile profile) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/profile'),
      headers: _headers(token),
      body: jsonEncode(_toJson(profile)),
    ).timeout(const Duration(seconds: 12));
    _ensureSuccess(response);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return _fromJson(payload['data'] as Map<String, dynamic>);
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _toJson(UserProfile profile) => {
    'goal': profile.goal,
    'birthDate': profile.birthDate?.toIso8601String().substring(0, 10),
    'weight': profile.weight,
    'height': profile.height,
    'sport': profile.sport,
    'trainingPlace': profile.trainingPlace,
    'injuries': profile.injuries,
    'pain': profile.pain,
    'surgeries': profile.surgeries,
    'diseases': profile.diseases,
    'allergies': profile.allergies,
    'trainingDays': profile.trainingDays,
    'notificationsEnabled': profile.notificationsEnabled,
    'privateProfile': profile.privateProfile,
  };

  UserProfile _fromJson(Map<String, dynamic> data) => UserProfile(
    goal: data['goal'] as String? ?? 'Mantenerme activo',
    birthDate: data['birthDate'] == null
        ? null
        : DateTime.tryParse(data['birthDate'] as String),
    weight: _number(data['weight']),
    height: _number(data['height']),
    sport: data['sport'] as String? ?? '',
    trainingPlace: data['trainingPlace'] as String? ?? '',
    injuries: data['injuries'] as String? ?? '',
    pain: data['pain'] as String? ?? '',
    surgeries: data['surgeries'] as String? ?? '',
    diseases: data['diseases'] as String? ?? '',
    allergies: data['allergies'] as String? ?? '',
    trainingDays: data['trainingDays'] is num ? (data['trainingDays'] as num).toInt() : 4,
    notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
    privateProfile: data['privateProfile'] as bool? ?? true,
  );

  double? _number(dynamic value) => value is num ? value.toDouble() : null;

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo guardar el perfil.');
    }
  }
}
