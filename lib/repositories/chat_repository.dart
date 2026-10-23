import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';

class ChatRepository {
  ChatRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<String> sendMessage({
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
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('El asistente no pudo responder en este momento.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    final text = data is Map<String, dynamic> ? data['message'] : null;
    if (text is! String || text.trim().isEmpty) {
      throw const FormatException('Respuesta vacía del asistente.');
    }
    return text;
  }
}
