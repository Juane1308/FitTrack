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
    id: (json['id'] as num?)?.toInt() ?? 0,
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
