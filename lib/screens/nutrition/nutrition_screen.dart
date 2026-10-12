import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/nutrition_food.dart';
import '../../repositories/nutrition_food_repository.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_title.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  static const _categories = <_FoodCategory>[
    _FoodCategory(
      'proteinas',
      'Proteínas magras',
      'Aportan aminoácidos que el cuerpo utiliza para formar y reparar tejidos.',
      Icons.fitness_center,
      'proteinas.png',
    ),
    _FoodCategory(
      'carbohidratos',
      'Carbohidratos',
      'Son una fuente importante de energía para las actividades diarias.',
      Icons.bolt,
      'carbohidratos.png',
    ),
    _FoodCategory(
      'grasas',
      'Grasas saludables',
      'Contribuyen al aporte de energía y a la absorción de algunas vitaminas.',
      Icons.opacity,
      'grasas.png',
    ),
    _FoodCategory(
      'vitaminas',
      'Vitaminas',
      'Micronutrientes que participan en funciones esenciales del organismo.',
      Icons.medical_services_outlined,
      'vitaminas.png',
    ),
    _FoodCategory(
      'minerales',
      'Minerales',
      'Nutrientes que contribuyen a funciones como la salud de huesos y músculos.',
      Icons.grain,
      'minerales.png',
    ),
    _FoodCategory(
      'frutas_verduras',
      'Frutas y verduras',
      'Pueden aportar fibra, vitaminas y minerales a una alimentación variada.',
      Icons.eco_outlined,
      'frutas_verduras.png',
    ),
    _FoodCategory(
      'legumbres',
      'Legumbres',
      'Ofrecen fibra y proteínas de origen vegetal.',
      Icons.grass,
      'legumbres.png',
    ),
    _FoodCategory(
      'lacteos',
      'Lácteos y alternativas',
      'Pueden aportar proteínas y otros nutrientes, según el producto.',
      Icons.local_drink_outlined,
      'lacteos.png',
    ),
  ];

  static const _recipeCategories = <_RecipeCategory>[
    _RecipeCategory(
      'desayunos',
      'Desayunos',
      'Opciones saludables para comenzar el día.',
      'assets/images/nutrition_breakfast.jpg',
      Icons.breakfast_dining,
    ),
    _RecipeCategory(
      'almuerzos',
      'Almuerzos',
      'Ideas equilibradas para la comida del mediodía.',
      'assets/images/nutrition_lunch.jpg',
      Icons.lunch_dining,
    ),
    _RecipeCategory(
      'comidas',
      'Comidas y cenas',
      'Recetas nutritivas para tus comidas principales.',
      'assets/images/nutrition_dinner.jpg',
      Icons.dinner_dining,
    ),
    _RecipeCategory(
      'snacks',
      'Snacks',
      'Pequeñas opciones para disfrutar entre comidas.',
      'assets/images/nutrition_snack.jpg',
      Icons.cookie_outlined,
    ),
    _RecipeCategory(
      'bebidas',
      'Bebidas',
      'Bebidas para acompañar una alimentación equilibrada.',
      null,
      Icons.local_drink_outlined,
    ),
    _RecipeCategory(
      'dulces',
      'Dulces saludables',
      'Alternativas dulces para disfrutar ocasionalmente.',
      'assets/images/nutrition_sweets.jpg',
      Icons.cake_outlined,
    ),
  ];

  final _repository = NutritionFoodRepository();
  int _activeTab = 0;
  _FoodCategory? _selectedCategory;
  _RecipeCategory? _selectedRecipeCategory;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedCategory;
    final selectedRecipe = _selectedRecipeCategory;
    final selectionTitle = _activeTab == 0 ? selected?.name : selectedRecipe?.name;
    final selectionDescription = _activeTab == 0
        ? selected?.description
        : selectedRecipe?.description;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectionTitle != null)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          if (_activeTab == 0) {
                            _selectedCategory = null;
                          } else {
                            _selectedRecipeCategory = null;
                          }
                        }),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(
                          _activeTab == 0 ? 'Clasificaciones' : 'Categorías',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    SectionTitle(
                      title: selectionTitle ?? (_activeTab == 0 ? 'Alimentos' : 'Recetas'),
                      subtitle: selectionDescription ?? (_activeTab == 0
                          ? 'Conoce los grupos de alimentos y lo que aportan.'
                          : 'Explora recetas saludables clasificadas por momento del día.'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('Alimentos'),
                        icon: Icon(Icons.restaurant_menu),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Recetas'),
                        icon: Icon(Icons.menu_book_outlined),
                      ),
                    ],
                    selected: {_activeTab},
                    onSelectionChanged: (selection) => setState(() {
                      _activeTab = selection.first;
                      _selectedCategory = null;
                      _selectedRecipeCategory = null;
                    }),
                  ),
                ),
              ),
              Expanded(
                child: _activeTab == 0
                    ? (selected == null ? _categoryList() : _foodList(selected))
                    : (selectedRecipe == null
                          ? _recipeCategoryList()
                          : _emptyRecipeCategory(selectedRecipe)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryList() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
    children: [
      Text(
        'Clasificaciones de alimentos',
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      for (final category in _categories) ...[
        _categoryCard(category),
        const SizedBox(height: 12),
      ],
    ],
  );

  Widget _recipeCategoryList() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
    children: [
      Text(
        'Categorías de recetas',
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      const Text(
        'Elige el momento del día para explorar las recetas.',
        style: TextStyle(color: AppColors.mutedText, height: 1.4),
      ),
      const SizedBox(height: 16),
      for (final category in _recipeCategories) ...[
        _recipeCategoryCard(category),
        const SizedBox(height: 12),
      ],
    ],
  );

  Widget _recipeCategoryCard(_RecipeCategory category) => AppCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: () => setState(() => _selectedRecipeCategory = category),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 124,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(19),
              ),
              child: category.image == null
                  ? _recipeCategoryFallback(category)
                  : Image.asset(
                      category.image!,
                      width: 110,
                      height: 124,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _recipeCategoryFallback(category),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      height: 1.3,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Ver recetas',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.chevron_right, color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _recipeCategoryFallback(_RecipeCategory category) => Container(
    width: 110,
    height: 124,
    color: AppColors.primary.withValues(alpha: .12),
    child: Icon(category.icon, color: AppColors.primary, size: 34),
  );

  Widget _emptyRecipeCategory(_RecipeCategory category) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
    children: [
      AppCard(
        child: Column(
          children: [
            Icon(category.icon, color: AppColors.primary, size: 36),
            const SizedBox(height: 12),
            Text(
              'Recetas de ${category.name.toLowerCase()}',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'El contenido de esta categoría se agregará en el siguiente requisito.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, height: 1.4),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _categoryCard(_FoodCategory category) => AppCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 124,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(19),
              ),
              child: Image.asset(
                'assets/images/nutrition/foods/categories/${category.image}',
                width: 110,
                height: 124,
                fit: BoxFit.cover,
                semanticLabel: 'Imagen de ${category.name.toLowerCase()}',
                errorBuilder: (_, _, _) => Container(
                  width: 110,
                  height: 124,
                  color: AppColors.primary.withValues(alpha: .12),
                  child: Icon(category.icon, color: AppColors.primary, size: 34),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      height: 1.3,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Ver alimentos',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.chevron_right, color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _foodList(_FoodCategory category) => FutureBuilder<List<NutritionFood>>(
    future: _repository.loadFoods(category.id),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _loadMessage(
          'No se pudo cargar esta clasificación.',
          onRetry: () => setState(() {}),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final foods = snapshot.data!;
      if (foods.isEmpty) {
        return _loadMessage('Aún no hay alimentos en esta clasificación.');
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const Text(
            'Información nutricional aproximada por cada 100 g.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 14),
          for (final food in foods) ...[
            _foodCard(food),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          const Text(
            'Datos de USDA FoodData Central. Los valores pueden variar según la variedad y preparación.',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      );
    },
  );

  Widget _loadMessage(String message, {VoidCallback? onRetry}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _foodCard(NutritionFood food) => AppCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: () => _showFood(food),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: Image.asset(
              food.imageUrl,
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 150,
                color: AppColors.primary.withValues(alpha: .12),
                child: const Center(
                  child: Icon(
                    Icons.restaurant,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${food.calories.toStringAsFixed(0)} kcal · ${food.serving}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _macroLabel('Proteína', food.protein),
                    _macroLabel('Carbohidratos', food.carbohydrates),
                    _macroLabel('Grasas', food.fat),
                    _macroLabel('Fibra', food.fiber),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Toca para conocer sus beneficios',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _macroLabel(String label, num grams) => Text(
    '$label ${grams.toStringAsFixed(1)} g',
    style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
  );

  void _showFood(NutritionFood food) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                food.imageUrl,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(food.description),
                    const SizedBox(height: 16),
                    Text(
                      'Aporte aproximado por ${food.serving}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text('${food.calories.toStringAsFixed(0)} kcal'),
                    const SizedBox(height: 4),
                    Text('Proteína: ${food.protein.toStringAsFixed(1)} g'),
                    Text(
                      'Carbohidratos: ${food.carbohydrates.toStringAsFixed(1)} g',
                    ),
                    Text('Grasas: ${food.fat.toStringAsFixed(1)} g'),
                    Text('Fibra: ${food.fiber.toStringAsFixed(1)} g'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _FoodCategory {
  const _FoodCategory(
    this.id,
    this.name,
    this.description,
    this.icon,
    this.image,
  );

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String image;
}

class _RecipeCategory {
  const _RecipeCategory(
    this.id,
    this.name,
    this.description,
    this.image,
    this.icon,
  );

  final String id;
  final String name;
  final String description;
  final String? image;
  final IconData icon;
}
