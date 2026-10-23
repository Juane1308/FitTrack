import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/recommendation_provider.dart';
import 'exercise_detail_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  static const _groups = <String, String>{
    'all': 'Todos',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'hombros': 'Hombros',
    'espalda': 'Espalda',
    'pecho': 'Pecho',
    'pierna': 'Pierna',
    'abdomen': 'Abdomen',
  };
  int _tab = 0;
  String _group = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      final token = context.read<AuthProvider>().sessionToken;
      if (token != null) {
        context.read<TrainingProvider>().loadWeeklyPlan(token);
        context.read<RecommendationProvider>().load(token);
      }
    });
  }

  void _load({bool forceRefresh = false}) {
    final goal = context.read<AppStateProvider>().profile.goal;
    context.read<TrainingProvider>().loadExercises(forceRefresh: forceRefresh, group: _group, goal: goal);
  }

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingProvider>();
    final recommendation = context.watch<RecommendationProvider>().recommendation;
    final state = context.watch<AppStateProvider>();
    final plan = training.weeklyPlan;
    final profile = state.profile;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Entrenamientos', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
                  IconButton(tooltip: 'Buscar ejercicios', onPressed: () => setState(() => _tab = 1), icon: const Icon(Icons.search), style: IconButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: const StadiumBorder())),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _TabButton(label: 'Rutinas', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                  _TabButton(label: 'Ejercicios', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                  _TabButton(label: 'Mis rutinas', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
                ],
              ),
              const SizedBox(height: 18),
              if (_tab == 0 && recommendation != null) ...[
                _RecommendationCard(recommendation: recommendation, training: true),
                const SizedBox(height: 14),
              ],
              if (_tab == 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _groups.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(label: Text(entry.value), selected: _group == entry.key, onSelected: training.isLoading ? null : (_) => setState(() { _group = entry.key; _load(forceRefresh: true); })),
                  )).toList()),
                ),
                const SizedBox(height: 14),
                if (training.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (training.exercises.isEmpty)
                  const _EmptyTraining(text: 'No hay ejercicios disponibles.')
                else
                  ...training.exercises.map((exercise) => _ExerciseRow(exercise: exercise)),
              ] else if (_tab == 2)
                const _EmptyTraining(text: 'Tus rutinas guardadas aparecerán aquí.')
              else if (training.weekLoading && plan.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (plan.isEmpty)
                _EmptyTraining(text: training.weekError ?? 'No se pudo generar tu rutina semanal.')
              else
                ...plan.map((day) => _RoutineRow(day: day)),
              if (profile.injuries.trim().isNotEmpty || profile.surgeries.trim().isNotEmpty)
                const Padding(padding: EdgeInsets.only(top: 14), child: Text('Revisa tus antecedentes antes de entrenar y consulta a un profesional si tienes dudas.', style: TextStyle(color: AppColors.mutedText, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(children: [Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.mutedText, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Container(height: 3, width: 56, color: selected ? AppColors.primary : Colors.transparent)]))));
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.day});

  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: AppColors.surface.withValues(alpha: .45), border: Border.all(color: AppColors.primary.withValues(alpha: .55))),
      child: Row(children: [
        _RoutineImage(url: day.exercises.isEmpty ? null : day.exercises.first.imageUrl, icon: Icons.fitness_center),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${day.dayLabel} · ${day.muscleGroup}', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(day.title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${day.durationMinutes} min · ${day.exercises.length} ejercicios', style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
        ])),
        Checkbox(value: day.completed, onChanged: (value) {
          final token = context.read<AuthProvider>().sessionToken;
          if (token != null) context.read<TrainingProvider>().toggleDay(token, day);
        }),
      ]),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ExerciseDetailScreen(exercise: exercise))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: AppColors.surface.withValues(alpha: .4), border: Border.all(color: const Color(0xFF1A2822))),
        child: Row(children: [_RoutineImage(url: exercise.imageUrl, icon: Icons.fitness_center_outlined), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('${exercise.primaryMuscle.isEmpty ? exercise.muscleCategory : exercise.primaryMuscle} · ${exercise.sets} series', style: const TextStyle(color: AppColors.mutedText, fontSize: 11))])), const Icon(Icons.chevron_right)]),
      ),
    );
  }
}

class _RoutineImage extends StatelessWidget {
  const _RoutineImage({required this.icon, this.url});

  final IconData icon;
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url!, width: 94, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()));
    }
    return _fallback();
  }

  Widget _fallback() => Container(width: 94, height: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C6B4D), Color(0xFF060908)])), child: Icon(icon, color: AppColors.primary, size: 30));
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation, required this.training});

  final PersonalizedRecommendation recommendation;
  final bool training;

  @override
  Widget build(BuildContext context) {
    final title = training ? recommendation.trainingTitle : recommendation.nutritionMethod;
    final summary = training ? recommendation.trainingSummary : recommendation.nutritionSummary;
    final items = training ? recommendation.safetyNotes : recommendation.meals;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF063B2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: .45))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.auto_awesome, color: AppColors.primary, size: 19), const SizedBox(width: 8), Expanded(child: Text('Recomendación ${recommendation.generatedBy == 'gemini' ? 'de Gemini' : 'FITTRACK'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)))]),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(summary, style: const TextStyle(color: AppColors.mutedText)),
        ...items.take(3).map((item) => Padding(padding: const EdgeInsets.only(top: 6), child: Text('• $item', style: const TextStyle(fontSize: 12)))),
      ]),
    );
  }
}

class _EmptyTraining extends StatelessWidget {
  const _EmptyTraining({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: .4), borderRadius: BorderRadius.circular(15)), child: Text(text, style: const TextStyle(color: AppColors.mutedText)));
}
