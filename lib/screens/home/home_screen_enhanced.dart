import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/charts/weekly_activity_chart.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_title.dart';

class HomeScreenEnhanced extends StatelessWidget {
  const HomeScreenEnhanced({this.onOpenTraining, this.onOpenProgress, super.key});

  final VoidCallback? onOpenTraining;
  final VoidCallback? onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final dashboard = state.dashboard;
    final user = context.watch<AuthProvider>().currentUser;
    final progress = context.watch<ProgressProvider>().data;
    if (user == null) return const SizedBox.shrink();

    final summary = progress.summary;
    final plannedDays = summary.plannedDays > 0 ? summary.plannedDays : dashboard.weeklyGoal;
    final completedDays = summary.plannedDays > 0 ? summary.completedDays : (dashboard.progressPercent * plannedDays).round();
    final progressPercent = plannedDays == 0 ? 0.0 : (completedDays / plannedDays).clamp(0.0, 1.0).toDouble();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hola, ${user.name}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.text)),
                  const SizedBox(height: 6),
                  Text('Tu plan se adapta a ${user.goal.toLowerCase()}.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.mutedText)),
                ])),
                const CircleAvatar(backgroundColor: AppColors.surface, child: Icon(Icons.person_outline, color: AppColors.primary)),
              ]),
              const SizedBox(height: 22),
              AppCard(child: Row(children: [
                SizedBox(width: 104, height: 104, child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(value: progressPercent, strokeWidth: 10, backgroundColor: const Color(0xFF20352D), color: AppColors.primary),
                  Text('${(progressPercent * 100).round()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ])),
                const SizedBox(width: 18),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tu progreso esta semana', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 8),
                  Text('$completedDays de $plannedDays entrenamientos completados', style: const TextStyle(color: AppColors.mutedText)),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(value: progressPercent, minHeight: 7, borderRadius: BorderRadius.circular(8)),
                ])),
              ])),
              const SizedBox(height: 18),
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle(title: 'Entrenamiento de hoy', subtitle: 'Generado con tu objetivo y tu perfil'),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.fitness_center, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(dashboard.routineName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                  IconButton(onPressed: onOpenTraining, icon: const Icon(Icons.arrow_forward_ios, size: 18), tooltip: 'Abrir entrenamiento'),
                ]),
                if (dashboard.durationMinutes > 0) ...[
                  const SizedBox(height: 4),
                  Text('${dashboard.routineDate} · ${dashboard.durationMinutes} min · ${dashboard.difficulty}', style: const TextStyle(color: AppColors.mutedText)),
                ],
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onOpenTraining, icon: const Icon(Icons.play_arrow), label: const Text('Comenzar entrenamiento'))),
              ])),
              const SizedBox(height: 18),
              const SectionTitle(title: 'Actividad semanal', subtitle: 'Marca cada día al completar tu rutina'),
              const SizedBox(height: 12),
              AppCard(child: WeeklyActivityChart(points: progress.weekly)),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth > 650 ? 4 : 2;
                return GridView.count(crossAxisCount: columns, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35, children: [
                  _MetricCard(icon: Icons.calendar_month_outlined, label: 'Días activos', value: '$completedDays/$plannedDays'),
                  _MetricCard(icon: Icons.timer_outlined, label: 'Tiempo semanal', value: '${summary.totalMinutes} min'),
                  _MetricCard(icon: Icons.local_fire_department_outlined, label: 'Racha actual', value: '${summary.activeStreak} días'),
                  _MetricCard(icon: Icons.monitor_weight_outlined, label: 'Peso actual', value: summary.currentWeight == null ? 'Sin registro' : '${summary.currentWeight!.toStringAsFixed(1)} kg'),
                ]);
              }),
              const SizedBox(height: 18),
              OutlinedButton.icon(onPressed: onOpenProgress, icon: const Icon(Icons.analytics_outlined), label: const Text('Ver análisis completo del progreso')),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Icon(icon, color: AppColors.primary),
    Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
  ]));
}
