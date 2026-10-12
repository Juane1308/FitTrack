import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
      'Proteínas magras',
      'Aportan aminoácidos que el cuerpo utiliza para formar y reparar tejidos.',
      Icons.fitness_center,
      'proteinas.png',
    ),
    _FoodCategory(
      'Carbohidratos',
      'Son una fuente importante de energía para las actividades diarias.',
      Icons.bolt,
      'carbohidratos.png',
    ),
    _FoodCategory(
      'Grasas saludables',
      'Contribuyen al aporte de energía y a la absorción de algunas vitaminas.',
      Icons.opacity,
      'grasas.png',
    ),
    _FoodCategory(
      'Vitaminas',
      'Micronutrientes que participan en funciones esenciales del organismo.',
      Icons.medical_services_outlined,
      'vitaminas.png',
    ),
    _FoodCategory(
      'Minerales',
      'Nutrientes que contribuyen a funciones como la salud de huesos y músculos.',
      Icons.grain,
      'minerales.png',
    ),
    _FoodCategory(
      'Frutas y verduras',
      'Pueden aportar fibra, vitaminas y minerales a una alimentación variada.',
      Icons.eco_outlined,
      'frutas_verduras.png',
    ),
    _FoodCategory(
      'Legumbres',
      'Ofrecen fibra y proteínas de origen vegetal.',
      Icons.grass,
      'legumbres.png',
    ),
    _FoodCategory(
      'Lácteos y alternativas',
      'Pueden aportar proteínas y otros nutrientes, según el producto.',
      Icons.local_drink_outlined,
      'lacteos.png',
    ),
  ];

  _FoodCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedCategory;

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
                    if (selected != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedCategory = null),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Clasificaciones'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    SectionTitle(
                      title: selected?.name ?? 'Alimentos',
                      subtitle: selected == null
                          ? 'Conoce los grupos de alimentos y lo que aportan.'
                          : selected.description,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selected == null
                    ? ListView(
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
                      )
                    : _emptyCategory(selected),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    'Ver clasificación',
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

  Widget _emptyCategory(_FoodCategory category) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
    children: [
      AppCard(
        child: Column(
          children: [
            Icon(category.icon, color: AppColors.primary, size: 36),
            const SizedBox(height: 12),
            Text(
              'Alimentos de ${category.name.toLowerCase()}',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'El contenido de esta clasificación se agregará en el siguiente requisito.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, height: 1.4),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FoodCategory {
  const _FoodCategory(this.name, this.description, this.icon, this.image);

  final String name;
  final String description;
  final IconData icon;
  final String image;
}
