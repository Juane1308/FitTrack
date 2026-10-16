import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/nutrition_recipe.dart';
import '../../repositories/nutrition_recipe_repository.dart';
import '../../widgets/common/app_card.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  static const _recipeCategories = <_Category>[
    _Category('desayunos', 'Desayunos', 'assets/images/nutrition_breakfast.jpg'),
    _Category('almuerzos', 'Almuerzos', 'assets/images/nutrition_lunch.jpg'),
    _Category('comidas', 'Cenas y comidas', 'assets/images/nutrition_dinner.jpg'),
    _Category('snacks', 'Snacks', 'assets/images/nutrition_snack.jpg'),
    _Category('bebidas', 'Bebidas', 'assets/images/nutrition_breakfast.jpg'),
    _Category('dulces', 'Dulces saludables', 'assets/images/nutrition_sweets.jpg'),
  ];
  static const _foodCategories = <_FoodCategory>[
    _FoodCategory('carbohidratos', 'Carbohidratos', 'Energía para el cerebro y el movimiento.', Icons.bolt, 'categories/categoria-carbohidratos.jpg'),
    _FoodCategory('proteinas', 'Proteínas', 'Aminoácidos para formar y reparar tejidos.', Icons.fitness_center, 'categories/categoria-proteinas.jpg'),
    _FoodCategory('grasas', 'Grasas saludables', 'Energía y apoyo en la absorción de vitaminas.', Icons.opacity, 'categories/categoria-grasas.jpg'),
    _FoodCategory('frutas', 'Frutas', 'Fibra, agua y micronutrientes para una alimentación variada.', Icons.local_florist_outlined, 'categories/categoria-frutas.jpg'),
    _FoodCategory('verduras', 'Verduras', 'Alimentos ricos en fibra y diversos micronutrientes.', Icons.eco, 'categories/categoria-verduras.jpg'),
    _FoodCategory('legumbres', 'Legumbres', 'Fibra y proteínas de origen vegetal.', Icons.spa_outlined, 'categories/categoria-legumbres.jpg'),
    _FoodCategory('lacteos', 'Lácteos y alternativas', 'Opciones que pueden aportar proteínas y otros nutrientes.', Icons.local_drink_outlined, 'categories/categoria-lacteos.jpg'),
  ];

  final _repository = NutritionRecipeRepository();
  String? _selectedRecipeCategory;
  String? _selectedFoodCategory;
  int _activeTab = 0;
  final Map<String, List<NutritionRecipe>> _extraRecipes = {};
  final Map<String, int> _recipeOffsets = {};
  final Map<String, bool> _recipeHasMore = {};
  final Map<String, String> _loadMoreErrors = {};
  bool _loadingMoreRecipes = false;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: _buildHeading()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  onTap: (index) => setState(() => _activeTab = index),
                  tabs: const [Tab(text: 'Alimentos'), Tab(text: 'Recetas')],
                ),
              ),
              Expanded(child: TabBarView(children: [_buildFoodSection(), _buildRecipeSection()])),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildHeading() {
    final categoryName = _activeTab == 0
        ? _labelForFood(_selectedFoodCategory)
        : _labelForRecipe(_selectedRecipeCategory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryName != null)
          TextButton.icon(
            onPressed: () => setState(() {
              if (_activeTab == 0) _selectedFoodCategory = null;
              else _selectedRecipeCategory = null;
            }),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(_activeTab == 0 ? 'Clasificaciones' : 'Categorías'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
          ),
        Text(
          categoryName ?? 'Una buena alimentación\ntambién te acerca a tus metas.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: categoryName == null ? 25 : 24,
            height: 1.16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        Container(
          width: 54,
          height: 3,
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildRecipeSection() {
    final selected = _selectedRecipeCategory;
    if (selected == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          const Text('Explora opciones saludables para cada momento del día.', style: TextStyle(color: AppColors.mutedText, height: 1.4)),
          const SizedBox(height: 18),
          for (final category in _recipeCategories) ...[
            _categoryCard(category),
            const SizedBox(height: 14),
          ],
          const _Disclaimer(),
        ],
      );
    }
    return FutureBuilder<NutritionRecipePage>(
      future: _repository.loadRecipes(selected),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorList(snapshot.error, () => setState(() {}));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final firstPage = snapshot.data!;
        final recipes = [...firstPage.recipes, ...?_extraRecipes[selected]];
        final hasMore = _recipeHasMore[selected] ?? firstPage.hasMore;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Text('${recipes.length} de ${firstPage.totalResults} recetas saludables', style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
            const SizedBox(height: 12),
            if (recipes.isEmpty) _messageCard('No encontramos recetas para esta categoría por ahora.'),
            for (final recipe in recipes) ...[_recipeCard(recipe), const SizedBox(height: 14)],
            if (_loadMoreErrors[selected] != null) _messageCard(_loadMoreErrors[selected]!),
            if (hasMore) ...[
              const SizedBox(height: 4),
              Center(child: OutlinedButton.icon(
                onPressed: _loadingMoreRecipes ? null : () => _loadMoreRecipes(selected, firstPage),
                icon: _loadingMoreRecipes ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.expand_more),
                label: Text(_loadingMoreRecipes ? 'Cargando recetas…' : 'Cargar más recetas'),
              )),
            ],
            const _Disclaimer(),
            const SizedBox(height: 8),
            const Text('Recetas de un conjunto de datos público de Kaggle. Las calorías y macronutrientes son valores de referencia por porción.', style: TextStyle(color: AppColors.mutedText, fontSize: 11, height: 1.4)),
          ],
        );
      },
    );
  }

  Widget _buildFoodSection() {
    final selected = _selectedFoodCategory;
    if (selected == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Text('¿Qué aportan los alimentos?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Consulta ejemplos y conoce su aporte nutricional por cada 100 gramos.', style: TextStyle(color: AppColors.mutedText, height: 1.4)),
          const SizedBox(height: 18),
          for (final category in _foodCategories) ...[
            _foodCategoryCard(category),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          const Text('Información educativa general. Las porciones y necesidades cambian según cada persona.', style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.4)),
        ],
      );
    }
    return FutureBuilder<List<NutritionFood>>(
      future: _repository.loadFoods(selected),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorList(snapshot.error, () => setState(() {}));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final foods = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            const Text('Valores aproximados por cada 100 g.', style: TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 14),
            if (foods.isEmpty) _messageCard('No se pudieron cargar alimentos de esta clasificación.'),
            for (final food in foods) ...[_foodCard(food), const SizedBox(height: 12)],
            const SizedBox(height: 4),
            const Text('Valores de USDA FoodData Central por cada 100 g; pueden variar según la variedad y preparación del alimento.', style: TextStyle(color: AppColors.mutedText, fontSize: 11, height: 1.4)),
          ],
        );
      },
    );
  }

  Widget _categoryCard(_Category category) => AppCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: () => setState(() => _selectedRecipeCategory = category.id),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 124,
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(19)),
            child: Image.asset(category.image, width: 110, height: 124, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(category.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Ver recetas', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
          ])),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.chevron_right, color: AppColors.mutedText)),
        ]),
      ),
    ),
  );

  Widget _foodCategoryCard(_FoodCategory category) => AppCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: () => setState(() => _selectedFoodCategory = category.id),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 124,
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(19)),
            child: Image.asset(
              category.imageAsset,
              width: 110,
              height: 124,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              semanticLabel: 'Imagen de ${category.label.toLowerCase()}',
              errorBuilder: (_, _, _) => Container(
                width: 110,
                height: 124,
                color: AppColors.primary.withValues(alpha: .12),
                child: Icon(category.icon, color: AppColors.primary, size: 34),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(category.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(category.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mutedText, height: 1.3, fontSize: 12)),
            const SizedBox(height: 5),
            const Text('Ver alimentos', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
          ])),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.chevron_right, color: AppColors.mutedText)),
        ]),
      ),
    ),
  );

  Widget _foodCard(NutritionFood food) => AppCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: () => _showFood(food),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 126,
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(food.imageUrl, width: 104, height: 110, fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                semanticLabel: 'Imagen de ${food.name}',
                errorBuilder: (_, _, _) => _imageFallback(110, width: 104)),
            ),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(food.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text('${food.calories.toStringAsFixed(0)} kcal · ${food.serving}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(spacing: 9, runSpacing: 3, children: [
                _compactMacro('Prot.', food.protein),
                _compactMacro('Carb.', food.carbohydrates),
                _compactMacro('Grasa', food.fat),
              ]),
            ]),
          )),
        ]),
      ),
    ),
  );

  Widget _recipeCard(NutritionRecipe recipe) => AppCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: () => _showRecipe(recipe),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 148,
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _image(recipe.imageUrl, recipe.name, 132, width: 112),
            ),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 9, 12, 9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(recipe.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Wrap(spacing: 9, runSpacing: 4, children: [
                _infoLabel(Icons.schedule, '${recipe.preparationMinutes} min'),
                _infoLabel(Icons.people_alt_outlined, '${recipe.portions} porciones'),
                _infoLabel(Icons.local_fire_department_outlined, recipe.caloriesLabel),
              ]),
              if (recipe.proteinGrams > 0) ...[
                const SizedBox(height: 6),
                Text('P ${recipe.proteinGrams} g · C ${recipe.carbohydratesGrams} g · G ${recipe.fatGrams} g', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mutedText, fontSize: 10.5)),
              ],
            ]),
          )),
        ]),
      ),
    ),
  );

  Widget _image(String url, String name, double height, {double? width}) => url.startsWith('assets/')
      ? Image.asset(url, width: width ?? double.infinity, height: height, fit: BoxFit.cover, semanticLabel: 'Fotografía de $name', errorBuilder: (_, _, _) => _imageFallback(height, width: width))
      : _imageFallback(height, width: width);

  Future<void> _loadMoreRecipes(String category, NutritionRecipePage firstPage) async {
    final offset = _recipeOffsets[category] ?? firstPage.recipes.length;
    setState(() { _loadingMoreRecipes = true; _loadMoreErrors.remove(category); });
    try {
      final page = await _repository.loadRecipes(category, offset: offset);
      if (!mounted) return;
      setState(() {
        _extraRecipes.update(category, (items) => [...items, ...page.recipes], ifAbsent: () => page.recipes);
        _recipeHasMore[category] = page.hasMore;
        if (page.hasMore) _recipeOffsets[category] = page.offset + page.recipes.length;
        else _recipeOffsets.remove(category);
      });
    } catch (error) {
      if (mounted) setState(() => _loadMoreErrors[category] = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingMoreRecipes = false);
    }
  }

  Widget _imageFallback(double height, {double? width}) => Container(width: width ?? double.infinity, height: height, color: AppColors.primary.withValues(alpha: .08), child: const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 32));

  Widget _infoLabel(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: AppColors.primary), const SizedBox(width: 5), Text(text, style: const TextStyle(color: AppColors.mutedText, fontSize: 11))]);

  Widget _macroLabel(String name, num value) => Text('$name ${value.toStringAsFixed(1)} g', style: const TextStyle(fontSize: 11, color: AppColors.mutedText));

  Widget _compactMacro(String name, num value) => Text('$name ${value.toStringAsFixed(0)} g', style: const TextStyle(fontSize: 10, color: AppColors.mutedText));

  void _showFood(NutritionFood food) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              food.imageUrl,
              width: double.infinity,
              height: 210,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) => _imageFallback(210),
            ),
          ),
          const SizedBox(height: 18),
          Text(food.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(food.description, style: const TextStyle(color: AppColors.mutedText, height: 1.5)),
          const SizedBox(height: 18),
          _detailHeading('Aporte aproximado por ${food.serving}'),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 8, children: [
            Text('Calorías ${food.calories.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
            _macroLabel('Proteína', food.protein),
            _macroLabel('Carbohidratos', food.carbohydrates),
            _macroLabel('Grasas', food.fat),
            _macroLabel('Fibra', food.fiber),
          ]),
          const SizedBox(height: 14),
          const Text('Información educativa general; los valores varían según la variedad y preparación.', style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.4)),
        ]),
      ),
    );
  }

  void _showRecipe(NutritionRecipe summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => FutureBuilder<NutritionRecipe>(
        future: _repository.loadRecipeDetail(summary.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) return SizedBox(height: 250, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage(snapshot.error), textAlign: TextAlign.center))));
          if (!snapshot.hasData) return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
          final recipe = snapshot.data!;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: .88,
            maxChildSize: .96,
            minChildSize: .55,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: _image(recipe.imageUrl, recipe.name, 230)),
                Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 14, runSpacing: 6, children: [
                    _infoLabel(Icons.schedule, '${recipe.preparationMinutes} min'),
                    _infoLabel(Icons.people_alt_outlined, '${recipe.portions} porciones'),
                    _infoLabel(Icons.local_fire_department_outlined, recipe.caloriesLabel),
                  ]),
                  const SizedBox(height: 12),
                  Text('Por porción: proteína ${recipe.proteinGrams} g · carbohidratos ${recipe.carbohydratesGrams} g · grasas ${recipe.fatGrams} g', style: const TextStyle(color: AppColors.mutedText, height: 1.4)),
                  const SizedBox(height: 20),
                  _detailHeading('Ingredientes'),
                  const SizedBox(height: 8),
                  for (final ingredient in recipe.ingredients) Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('•  ', style: TextStyle(color: AppColors.primary)), Expanded(child: Text(ingredient))])),
                  const SizedBox(height: 16),
                  _detailHeading('Preparación paso a paso'),
                  const SizedBox(height: 8),
                  for (var index = 0; index < recipe.steps.length; index++) Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${index + 1}.  ', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)), Expanded(child: Text(recipe.steps[index], style: const TextStyle(height: 1.45, color: AppColors.mutedText)))])),
                  if (recipe.steps.isEmpty) const Text('Los pasos detallados no están disponibles para esta receta.', style: TextStyle(color: AppColors.mutedText)),
                  const SizedBox(height: 18),
                  const _Disclaimer(),
                  if (recipe.sourceUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SelectableText('Fuente: ${recipe.sourceUrl}', style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
                  ],
                ])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailHeading(String text) => Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800));

  String? _labelForFood(String? id) {
    for (final category in _foodCategories) {
      if (category.id == id) return category.label;
    }
    return null;
  }

  String? _labelForRecipe(String? id) {
    for (final category in _recipeCategories) {
      if (category.id == id) return category.label;
    }
    return null;
  }

  Widget _messageCard(String message) => AppCard(child: Text(message, style: const TextStyle(color: AppColors.mutedText)));

  Widget _errorList(Object? error, VoidCallback onRetry) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_errorMessage(error), style: const TextStyle(color: AppColors.mutedText, height: 1.4)),
            const SizedBox(height: 8),
            const SizedBox(height: 10),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    ],
  );

  String _errorMessage(Object? error) => error is NutritionApiException ? error.message : 'No se pudo cargar la información nutricional.';
}

class _Category {
  const _Category(this.id, this.label, this.image);
  final String id;
  final String label;
  final String image;
}

class _FoodCategory {
  const _FoodCategory(this.id, this.label, this.description, this.icon, this.imageFile);
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final String imageFile;
  String get imageAsset => 'assets/images/nutrition/foods/$imageFile';
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
    child: const Text('Contenido informativo. No sustituye la orientación de un profesional de salud o nutrición.', style: TextStyle(color: AppColors.mutedText, fontSize: 11, height: 1.4)),
  );
}
