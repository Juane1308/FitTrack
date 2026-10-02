import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../common/module_placeholder_screen.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      section: AppSection.nutrition,
      icon: Icons.restaurant,
    );
  }
}
