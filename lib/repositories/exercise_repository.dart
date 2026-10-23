import 'dart:convert';

import 'package:flutter/services.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.level,
    required this.equipment,
    required this.muscles,
    required this.instructions,
    required this.images,
  });
  final String id, name, level, equipment;
  final List<String> muscles, instructions, images;
  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    level: j['level'] as String? ?? 'beginner',
    equipment: j['equipment'] as String? ?? 'body only',
    muscles: [
      ...(j['primaryMuscles'] as List? ?? const []),
      ...(j['secondaryMuscles'] as List? ?? const []),
    ].whereType<String>().toSet().toList(),
    instructions: (j['instructions'] as List? ?? const [])
        .whereType<String>()
        .toList(),
    images: (j['images'] as List? ?? const []).whereType<String>().toList(),
  );
  String get imageUrl => images.isEmpty
      ? ''
      : 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${images.first}';
}

class ExerciseRepository {
  Future<List<Exercise>> load() async {
    final raw = await rootBundle.loadString(
      'backend/data/exercises/exercises.json',
    );
    return (jsonDecode(raw) as List)
        .whereType<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList();
  }
}
