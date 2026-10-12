import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/nutrition_food.dart';

class NutritionFoodRepository {
  static const _datasetAsset = 'backend/data/nutrition/foods.json';
  static const _maxPerCategory = 10;

  Future<Map<String, List<NutritionFood>>>? _catalogFuture;

  Future<List<NutritionFood>> loadFoods(String category) async {
    final catalog = await (_catalogFuture ??= _loadCatalog());
    return catalog[category] ?? const [];
  }

  Future<Map<String, List<NutritionFood>>> _loadCatalog() async {
    try {
      final decoded = jsonDecode(await rootBundle.loadString(_datasetAsset));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('El catálogo de alimentos no es válido.');
      }
      final categories = decoded['categories'];
      if (categories is! Map<String, dynamic>) {
        throw const FormatException('El catálogo no contiene clasificaciones.');
      }

      return categories.map((category, rawFoods) {
        final foods = rawFoods is List
            ? rawFoods
                  .whereType<Map<String, dynamic>>()
                  .take(_maxPerCategory)
                  .map(NutritionFood.fromJson)
                  .toList(growable: false)
            : const <NutritionFood>[];
        return MapEntry(category, foods);
      });
    } catch (_) {
      _catalogFuture = null;
      rethrow;
    }
  }
}
