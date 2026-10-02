import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_title.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final dashboard = state.dashboard;
    final user = context.watch<AuthProvider>().currentUser ?? state.currentUser;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            children: [
              Text(
                'Hola, ${user.name} 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Listo para avanzar hacia tu objetivo: ${user.goal}.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 24),
              AppCard(
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rutina de hoy',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dashboard.routineName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${dashboard.routineDate}  ·  ${dashboard.durationMinutes} min  ·  ${dashboard.difficulty}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Ver rutina'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const SectionTitle(
                title: 'Tu resumen',
                subtitle: 'Indicadores mock para la primera etapa',
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 650 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _MetricCard(
                        icon: Icons.flag_outlined,
                        label: 'Meta semanal',
                        value: '${dashboard.weeklyGoal} días',
                      ),
                      _MetricCard(
                        icon: Icons.insights_outlined,
                        label: 'Progreso',
                        value: '${(dashboard.progressPercent * 100).round()}%',
                      ),
                      _MetricCard(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Calorías',
                        value: '${dashboard.calories.round()} kcal',
                      ),
                      _MetricCard(
                        icon: Icons.bolt_outlined,
                        label: 'Racha activa',
                        value: '${dashboard.activeStreak} días',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary),
          Text(
            label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
