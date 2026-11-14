import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/charts/weekly_activity_chart.dart';
import '../../widgets/common/app_card.dart';

class HomeScreenEnhanced extends StatelessWidget {
  const HomeScreenEnhanced({
    this.onOpenTraining,
    this.onOpenProgress,
    super.key,
  });

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
    final plannedDays = summary.plannedDays > 0
        ? summary.plannedDays
        : dashboard.weeklyGoal;
    final completedDays = summary.plannedDays > 0
        ? summary.completedDays
        : (dashboard.progressPercent * plannedDays).round();
    final progressPercent = plannedDays == 0
        ? 0.0
        : (completedDays / plannedDays).clamp(0.0, 1.0).toDouble();
    final canStart =
        dashboard.routineName.trim().isNotEmpty &&
        dashboard.routineName != 'Sin rutina';

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Image.network(
              ApiConfig.mediaUrl('home-background'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .45),
                    Colors.black.withValues(alpha: .78),
                    Colors.black.withValues(alpha: .96),
                  ],
                  stops: [0, .42, 1],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _DashboardGridPainter()),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                children: [
                  _Header(user: user),
                  const SizedBox(height: 22),
                  _WeeklyProgressCard(
                    completedDays: completedDays,
                    plannedDays: plannedDays,
                    progressPercent: progressPercent,
                    onOpenProgress: onOpenProgress,
                  ),
                  const SizedBox(height: 20),
                  _SectionHeading(
                    eyebrow: 'PLAN DE HOY',
                    title: canStart
                        ? dashboard.routineName
                        : 'Tu rutina está por definirse',
                    actionLabel: 'Ver entrenamiento',
                    onAction: onOpenTraining,
                  ),
                  const SizedBox(height: 10),
                  _TodayWorkoutCard(
                    dashboard: dashboard,
                    available: canStart,
                    onStart: onOpenTraining,
                  ),
                  const SizedBox(height: 20),
                  const _SectionHeading(
                    eyebrow: 'RESUMEN',
                    title: 'Tus métricas de la semana',
                  ),
                  const SizedBox(height: 10),
                  _MetricsGrid(
                    calories: dashboard.calories,
                    totalMinutes: summary.totalMinutes,
                    activeStreak: summary.activeStreak,
                  ),
                  const SizedBox(height: 20),
                  _ActivityCard(points: progress.weekly),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: onOpenProgress,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Ver análisis completo del progreso'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.toString().trim().split(' ').first;
    final initials = user.name
        .toString()
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $firstName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Disciplina hoy. Resultados mañana.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: null,
          tooltip: 'Notificaciones',
          icon: const Icon(Icons.notifications_none_outlined),
        ),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary.withValues(alpha: .65)),
          ),
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({
    required this.completedDays,
    required this.plannedDays,
    required this.progressPercent,
    this.onOpenProgress,
  });

  final int completedDays;
  final int plannedDays;
  final double progressPercent;
  final VoidCallback? onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final percent = (progressPercent * 100).round();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTA SEMANA',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Progreso de entrenamiento',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenProgress,
                tooltip: 'Ver progreso',
                icon: const Icon(
                  Icons.insights_outlined,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progressPercent,
                      strokeWidth: 9,
                      backgroundColor: const Color(0xFF20352D),
                      color: AppColors.primary,
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedDays de $plannedDays entrenamientos',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'completados',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF20352D),
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({
    required this.dashboard,
    required this.available,
    this.onStart,
  });

  final DashboardSummary dashboard;
  final bool available;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final routineImageUrl = dashboard.routineImageUrl?.isNotEmpty == true
        ? dashboard.routineImageUrl!
        : ApiConfig.mediaUrl('routine-cover');

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                routineImageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fitness_center_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .18),
                      Colors.black.withValues(alpha: .42),
                      Colors.black.withValues(alpha: .94),
                    ],
                    stops: const [0, .42, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: .5),
                            ),
                          ),
                          child: const Icon(
                            Icons.fitness_center_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      available ? dashboard.routineName : 'Sin rutina asignada',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      available
                          ? '${dashboard.routineDate} · ${dashboard.durationMinutes} min · ${dashboard.difficulty}'
                          : 'Abre Entrenar para configurar tu siguiente sesión.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onStart,
                        icon: Icon(
                          available
                              ? Icons.play_arrow_rounded
                              : Icons.tune_rounded,
                        ),
                        label: Text(
                          available
                              ? 'Comenzar entrenamiento'
                              : 'Configurar rutina',
                        ),
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

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.calories,
    required this.totalMinutes,
    required this.activeStreak,
  });

  final double calories;
  final int totalMinutes;
  final int activeStreak;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.local_fire_department_outlined,
        'Calorías semanales',
        calories > 0 ? _formatCalories(calories) : 'Sin datos',
      ),
      (
        Icons.schedule_outlined,
        'Tiempo semanal',
        _formatDuration(totalMinutes),
      ),
      (Icons.emoji_events_outlined, 'Racha', '$activeStreak días'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: constraints.maxWidth > 500 ? 10 : 6,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth > 500 ? 1.2 : .92,
          ),
          itemBuilder: (context, index) => _MetricCard(
            icon: items[index].$1,
            label: items[index].$2,
            value: items[index].$3,
          ),
        );
      },
    );
  }

  String _formatCalories(double value) => value.round().toString();

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '0 min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return hours == 0
        ? '$remainder min'
        : '$hours h ${remainder.toString().padLeft(2, '0')} min';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Center(child: Icon(icon, color: AppColors.primary, size: 21)),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.mutedText, fontSize: 9),
          ),
          FittedBox(
            alignment: Alignment.center,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.points});

  final List<WeeklyProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'ACTIVIDAD',
            title: 'Cumplimiento por día',
          ),
          const SizedBox(height: 4),
          const Text(
            'Tu constancia semanal, basada en sesiones completadas.',
            style: TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 18),
          WeeklyActivityChart(points: points),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _DashboardGridPainter extends CustomPainter {
  const _DashboardGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: .025)
      ..strokeWidth = 1;
    const gap = 36.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
