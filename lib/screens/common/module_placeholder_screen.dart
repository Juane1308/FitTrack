import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_title.dart';

class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({
    required this.section,
    required this.icon,
    super.key,
  });

  final AppSection section;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final count = switch (section) {
      AppSection.training => state.routines.length,
      AppSection.nutrition => state.foods.length + state.recipes.length,
      AppSection.progress => state.progress.length,
      AppSection.profile => 1,
      AppSection.home => 1,
    };

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            children: [
              SectionTitle(title: section.label, subtitle: section.description),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Módulo base preparado',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esta sección ya tiene navegación y datos mock separados de la interfaz.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 18),
                    Chip(
                      label: Text(
                        '$count registro${count == 1 ? '' : 's'} mock disponible${count == 1 ? '' : 's'}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
