import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../common/module_placeholder_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      section: AppSection.progress,
      icon: Icons.show_chart,
    );
  }
}
