import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/nutrition_recipe.dart';

class NutritionRecipeRepository {
  static const int _maxPerCategory = 10;
  static const String _recipesAsset = 'backend/data/nutrition/recipes.json';
  static const String _foodsAsset = 'backend/data/nutrition/foods.json';

  final Map<String, Future<NutritionRecipePage>> _recipeCache = {};
  final Map<String, Future<List<NutritionFood>>> _foodCache = {};
  final Map<int, Future<NutritionRecipe>> _detailCache = {};

  Future<NutritionRecipePage> loadRecipes(String category, {int offset = 0}) async {
    final key = '$category:$offset';
    try {
      return await _recipeCache.putIfAbsent(key, () async {
        final data = await _loadDataset(_recipesAsset);
        final allRecipes = _categoryItems(data, category)
            .map(NutritionRecipe.fromJson)
            .take(_maxPerCategory)
            .toList(growable: false);
        final safeOffset = offset.clamp(0, allRecipes.length) as int;
        final recipes = allRecipes.skip(safeOffset).toList(growable: false);
        return NutritionRecipePage(
          recipes: recipes,
          offset: safeOffset,
          totalResults: allRecipes.length,
          hasMore: safeOffset + recipes.length < allRecipes.length,
        );
      });
    } catch (_) {
      _recipeCache.remove(key);
      rethrow;
    }
  }

  Future<NutritionRecipe> loadRecipeDetail(int id) async {
    try {
      return await _detailCache.putIfAbsent(id, () async {
        final data = await _loadDataset(_recipesAsset);
        for (final category in _categories(data)) {
          for (final recipe in _asMaps(category)) {
            if ((recipe['id'] as num?)?.toInt() == id) {
              return NutritionRecipe.fromJson(recipe);
            }
          }
        }
        throw const NutritionApiException('No se encontró el detalle de la receta.');
      });
    } catch (_) {
      _detailCache.remove(id);
      rethrow;
    }
  }

  Future<List<NutritionFood>> loadFoods(String category) async {
    try {
      return await _foodCache.putIfAbsent(category, () async {
        final data = await _loadDataset(_foodsAsset);
        return _categoryItems(data, category)
            .take(_maxPerCategory)
            .map(NutritionFood.fromJson)
            .toList(growable: false);
      });
    } catch (_) {
      _foodCache.remove(category);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadDataset(String path) async {
    try {
      final body = jsonDecode(await rootBundle.loadString(path));
      if (body is! Map<String, dynamic>) {
        throw const NutritionApiException('El dataset nutricional tiene un formato inválido.');
      }
      return body;
    } on NutritionApiException {
      rethrow;
    } catch (error) {
      throw NutritionApiException('No se pudo leer el dataset local ($path): $error');
    }
  }

  List<dynamic> _categories(Map<String, dynamic> dataset) =>
      (dataset['categories'] as Map<String, dynamic>? ?? const {}).values.toList();

  List<Map<String, dynamic>> _asMaps(dynamic items) => (items as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  List<Map<String, dynamic>> _categoryItems(Map<String, dynamic> dataset, String category) {
    final categories = dataset['categories'] as Map<String, dynamic>? ?? const {};
    return _asMaps(categories[category]);
  }
}

class NutritionRecipePage {
  const NutritionRecipePage({required this.recipes, required this.offset, required this.totalResults, required this.hasMore});
  final List<NutritionRecipe> recipes;
  final int offset;
  final int totalResults;
  final bool hasMore;
}

class NutritionFood {
  const NutritionFood({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.serving,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
  });

  factory NutritionFood.fromJson(Map<String, dynamic> json) => NutritionFood(
    id: json['id'] as int? ?? 0,
    name: json['nombre'] as String? ?? 'Alimento',
    description: json['descripcion_saludable'] as String? ?? '',
    imageUrl: json['imagen_url'] as String? ?? '',
    serving: json['porcion'] as String? ?? '100 g',
    calories: json['calorias'] as num? ?? 0,
    protein: json['proteina_g'] as num? ?? 0,
    carbohydrates: json['carbohidratos_g'] as num? ?? 0,
    fat: json['grasas_g'] as num? ?? 0,
    fiber: json['fibra_g'] as num? ?? 0,
  );

  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String serving;
  final num calories;
  final num protein;
  final num carbohydrates;
  final num fat;
  final num fiber;
}

class NutritionApiException implements Exception {
  const NutritionApiException(this.message);
  final String message;
}
