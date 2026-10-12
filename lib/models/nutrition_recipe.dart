class NutritionRecipe {
  const NutritionRecipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.mainIngredients,
    required this.instructions,
    required this.steps,
    required this.categories,
    required this.diets,
    required this.imageUrl,
    required this.sourceUrl,
    required this.preparationMinutes,
    required this.portions,
    required this.approximateCalories,
    required this.nutritionNote,
    required this.difficulty,
    required this.proteinGrams,
    required this.carbohydratesGrams,
    required this.fatGrams,
  });

  factory NutritionRecipe.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) => (json[key] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);

    return NutritionRecipe(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['nombre'] as String? ?? 'Receta',
      ingredients: strings('ingredientes'),
      mainIngredients: strings('ingredientes_principales'),
      instructions: json['instrucciones'] as String? ?? '',
      steps: strings('pasos'),
      categories: strings('categorias_fittrack'),
      diets: strings('dieta'),
      imageUrl: json['imagen_url'] as String? ?? json['imagen'] as String? ?? '',
      sourceUrl: json['fuente_url'] as String? ?? '',
      preparationMinutes: (json['tiempo_minutos'] as num?)?.toInt() ?? 0,
      portions: (json['porciones'] as num?)?.toInt() ?? 1,
      approximateCalories: json['calorias_aprox'] as num? ?? 0,
      nutritionNote: json['valor_nutricional'] as String? ?? '',
      difficulty: json['dificultad'] as String? ?? '',
      proteinGrams: json['proteina_g'] as num? ?? 0,
      carbohydratesGrams: json['carbohidratos_g'] as num? ?? 0,
      fatGrams: json['grasas_g'] as num? ?? 0,
    );
  }

  final int id;
  final String name;
  final List<String> ingredients;
  final List<String> mainIngredients;
  final String instructions;
  final List<String> steps;
  final List<String> categories;
  final List<String> diets;
  final String imageUrl;
  final String sourceUrl;
  final int preparationMinutes;
  final int portions;
  final num approximateCalories;
  final String nutritionNote;
  final String difficulty;
  final num proteinGrams;
  final num carbohydratesGrams;
  final num fatGrams;

  String get caloriesLabel {
    final range = RegExp(r'\d+(?:\s*[-–]\s*\d+)?')
        .firstMatch(nutritionNote)
        ?.group(0)
        ?.replaceAll(' ', '');
    return range == null
        ? '${approximateCalories.toInt()} kcal aprox.'
        : '$range kcal aprox.';
  }
}
