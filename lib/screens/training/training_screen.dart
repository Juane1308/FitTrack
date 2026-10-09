import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../common/module_placeholder_screen.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      section: AppSection.training,
      icon: Icons.fitness_center,
    );
  }
}
