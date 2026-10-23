import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/training_provider.dart';
import '../../widgets/common/app_card.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({required this.exercise, super.key});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del ejercicio')),
      body: FutureBuilder<Exercise>(
        future: context.read<TrainingProvider>().loadDetails(exercise),
        initialData: exercise,
        builder: (context, snapshot) {
          final detail = snapshot.data ?? exercise;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (detail.imageUrl != null && detail.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(detail.imageUrl!, height: 220, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ExerciseFallback()),
                )
              else
                const _ExerciseFallback(),
              const SizedBox(height: 18),
              Text(
                detail.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(label: 'Series', value: '${detail.sets}'),
                    _Stat(label: 'Repeticiones', value: '${detail.repetitions}'),
                    if (detail.primaryMuscle.isNotEmpty)
                      _Stat(label: 'Músculo', value: detail.primaryMuscle),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Text(
                  'Recomendado para ${detail.recommendationFocus}. ${detail.sets} series de ${detail.recommendedRepetitions} repeticiones para tu meta.',
                ),
              ),
              const SizedBox(height: 16),
              if (detail.description.isNotEmpty) ...[
                AppCard(child: Text(detail.description)),
                const SizedBox(height: 16),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Técnica',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator()
                    else if (detail.instructions.isEmpty)
                      Text(detail.technique)
                    else
                      ...detail.instructions.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('${entry.key + 1}. ${entry.value}'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseFallback extends StatelessWidget {
  const _ExerciseFallback();

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)),
    child: const Center(child: Icon(Icons.fitness_center, size: 56, color: AppColors.primary)),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
        ],
      ),
    );
  }
}
