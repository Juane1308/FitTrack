import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/training_provider.dart';
import '../../utils/exercise_localization.dart';
import 'exercise_detail_screen.dart';

/// Entrenamiento mantiene los datos de catálogo y el plan semanal del backend,
/// y guarda localmente favoritos y rutinas creadas por el usuario.
class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  static const _groups = <String, String>{
    'all': 'Todos',
    'brazos': 'Brazos',
    'pecho': 'Pecho',
    'espalda': 'Espalda',
    'hombros': 'Hombros',
    'pierna': 'Piernas',
    'abdomen': 'Abdomen',
  };

  static const _savedKey = 'training.saved';
  static const _createdKey = 'training.created';

  int _tab = 0;
  String _group = 'all';
  String _exerciseQuery = '';
  String _routineQuery = '';
  bool _selectionMode = false;
  final Set<String> _selectedExercises = {};
  final Map<String, Exercise> _exerciseCache = {};
  final Map<String, _TrainingRoutine> _routineCache = {};
  Set<String> _savedRoutineIds = {};
  Map<String, List<String>> _createdRoutines = {};
  _TrainingRoutine? _selectedRoutine;
  int _detailTab = 0;

  bool _sessionActive = false;
  bool _sessionMinimized = false;
  bool _sessionPaused = false;
  bool _sessionComplete = false;
  bool _savingCompletion = false;
  bool _awaitingContinue = false;
  Timer? _sessionTicker;
  int _exerciseIndex = 0;
  int _setNumber = 1;
  int _elapsedSeconds = 0;
  int _sessionElapsedSeconds = 0;
  int _restSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _readLocalRoutines();
      if (!mounted) return;
      _load();
      final token = context.read<AuthProvider>().sessionToken;
      if (token != null) {
        context.read<TrainingProvider>().loadWeeklyPlan(token);
        context.read<RecommendationProvider>().load(token);
      }
    });
  }

  @override
  void dispose() {
    _sessionTicker?.cancel();
    super.dispose();
  }

  Future<void> _readLocalRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedKey) ?? const <String>[];
    final raw = prefs.getString(_createdKey);
    final decoded = raw == null ? null : _decodeCreated(raw);
    if (!mounted) return;
    setState(() {
      _savedRoutineIds = saved.toSet();
      _createdRoutines = decoded ?? {};
    });
  }

  Map<String, List<String>>? _decodeCreated(String raw) {
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return decoded.map(
        (name, ids) => MapEntry(
          name,
          ids is List ? ids.map((id) => id.toString()).toList() : <String>[],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistLocalRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, _savedRoutineIds.toList());
    await prefs.setString(_createdKey, jsonEncode(_createdRoutines));
  }

  void _load({bool forceRefresh = false}) {
    final goal = context.read<AppStateProvider>().profile.goal;
    context.read<TrainingProvider>().loadExercises(
      forceRefresh: forceRefresh,
      group: _group,
      goal: goal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final training = context.watch<TrainingProvider>();
    _exerciseCache.addEntries(
      training.exercises.map((exercise) => MapEntry(exercise.slug, exercise)),
    );
    _routineCache.addEntries(
      _catalogRoutines(training.exercises)
          .map((routine) => MapEntry(routine.id, routine)),
    );

    final Widget content;
    if (_sessionActive && !_sessionMinimized) {
      content = _buildSession();
    } else if (_selectedRoutine != null && !_sessionMinimized) {
      content = _buildRoutineDetails(_selectedRoutine!);
    } else {
      content = _buildTabs();
    }

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: content),
          if (_sessionActive && _sessionMinimized)
            Positioned(
              top: 10,
              right: 14,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                elevation: 8,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _sessionMinimized = false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatTime(_sessionElapsedSeconds)} · Rutina activa',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final training = context.watch<TrainingProvider>();
    final recommendation = context
        .watch<RecommendationProvider>()
        .recommendation;
    final plan = training.weeklyPlan;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'El esfuerzo de hoy es el éxito de mañana.',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _TabButton(
                        label: 'Rutinas',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      _TabButton(
                        label: 'Ejercicios',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                      _TabButton(
                        label: 'Mis rutinas',
                        selected: _tab == 2,
                        onTap: () => setState(() => _tab = 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_tab == 0) ...[
              _buildGroupFilters(training),
              _buildRoutineSearch(),
            ],
            if (_tab == 1) ...[
              _buildExerciseSearch(),
              _buildGroupFilters(training),
            ],
            Expanded(
              child: _tab == 0
                  ? _buildRoutineList(training, plan, recommendation)
                  : _tab == 1
                  ? _buildExerciseList(training)
                  : _buildMyRoutines(training, plan),
            ),
            if (_tab == 1) _buildSelectionActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupFilters(TrainingProvider training) => SizedBox(
    height: 50,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      children: _groups.entries.map((entry) {
        final selected = _group == entry.key;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: training.isLoading
                ? null
                : (_) {
                    setState(() => _group = entry.key);
                    _load(forceRefresh: true);
                  },
            selectedColor: const Color(0xFF254638),
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.mutedText,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFF293A33),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _buildExerciseSearch() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: TextField(
      onChanged: (value) =>
          setState(() => _exerciseQuery = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Buscar ejercicios',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _exerciseQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () => setState(() => _exerciseQuery = ''),
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _buildRoutineSearch() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: TextField(
      onChanged: (value) =>
          setState(() => _routineQuery = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Buscar rutinas',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _routineQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () => setState(() => _routineQuery = ''),
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _buildRoutineList(
    TrainingProvider training,
    List<WorkoutDay> plan,
    PersonalizedRecommendation? recommendation,
  ) {
    if (training.isLoading && training.exercises.isEmpty && plan.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final routines = _catalogRoutines(training.exercises);
    final query = _routineQuery.toLowerCase();
    final visible = routines
        .where(
          (routine) =>
              query.isEmpty ||
              '${routine.name} ${routine.group} ${routine.level}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (recommendation != null && _group == 'all') ...[
          _RecommendationCard(recommendation: recommendation),
          const SizedBox(height: 14),
        ],
        if (plan.isNotEmpty && _group == 'all') ...[
          const _SectionTitle(title: 'Tu plan semanal'),
          ...plan.map(
            (day) => _RoutineCard(
              routine: _TrainingRoutine.fromWorkoutDay(day),
              isSaved: _savedRoutineIds.contains('weekly:${day.date}'),
              completed: day.completed,
              onComplete: () => _toggleRoutineCompletion(day),
              onTap: () => _openRoutine(_TrainingRoutine.fromWorkoutDay(day)),
              onSave: () => _toggleSaved('weekly:${day.date}'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _SectionTitle(
          title: _group == 'all'
              ? 'Rutinas para entrenar'
              : 'Rutinas de ${_groups[_group]?.toLowerCase() ?? _group}',
        ),
        if (training.status == TrainingLoadStatus.error && routines.isEmpty)
          _EmptyTraining(
            text:
                training.errorMessage ??
                'No se pudo cargar el catálogo de ejercicios.',
          ),
        if (visible.isEmpty && training.status != TrainingLoadStatus.loading)
          const _EmptyTraining(
            text: 'No hay rutinas para esta búsqueda o clasificación.',
          ),
        ...visible.map(
          (routine) => _RoutineCard(
            routine: routine,
            isSaved: _savedRoutineIds.contains(routine.id),
            onTap: () => _openRoutine(routine),
            onSave: () => _toggleSaved(routine.id),
          ),
        ),
        if (training.isLoading)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  List<_TrainingRoutine> _catalogRoutines(List<Exercise> exercises) {
    if (exercises.isEmpty) return const [];
    final byGroup = <String, List<Exercise>>{};
    for (final exercise in exercises) {
      final key =
          exercise.muscleCategory == 'general' ||
              exercise.muscleCategory.isEmpty
          ? _groupFromText(
              '${exercise.group} ${exercise.primaryMuscle} ${exercise.name}',
            )
          : exercise.muscleCategory;
      if (_group != 'all' &&
          key != _group &&
          !(_group == 'brazos' && {'biceps', 'triceps'}.contains(key))) {
        continue;
      }
      byGroup.putIfAbsent(key, () => []).add(exercise);
    }

    const levels = <(String, String)>[
      ('beginner', 'Principiante'),
      ('intermediate', 'Intermedio'),
      ('expert', 'Avanzado'),
    ];
    final routines = <_TrainingRoutine>[];
    byGroup.forEach((key, items) {
      final label = _groupLabel(key);
      for (final (level, levelName) in levels) {
        final list = items
            .where((exercise) => _normalizedLevel(exercise.level) == level)
            .take(5)
            .toList();
        if (list.isEmpty) continue;
        routines.add(
          _TrainingRoutine(
            id: '${_legacyMuscleId(key)}_$level',
            name: 'Rutina de $label',
            group: label,
            level: levelName,
            durationMinutes:
                (list.length *
                        (level == 'beginner'
                            ? 4
                            : level == 'intermediate'
                            ? 5
                            : 6))
                    .clamp(15, 60)
                    .toInt(),
            calories:
                (list.length *
                (level == 'beginner'
                    ? 22
                    : level == 'intermediate'
                    ? 30
                    : 38)),
            exercises: List.unmodifiable(list),
          ),
        );
      }
    });
    _routineCache.addEntries(
      routines.map((routine) => MapEntry(routine.id, routine)),
    );
    return routines;
  }

  Widget _buildExerciseList(TrainingProvider training) {
    if (training.isLoading && training.exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (training.status == TrainingLoadStatus.error &&
        training.exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(training.errorMessage ?? 'No se pudo cargar el catálogo.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _load(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final exercises = training.exercises
        .where(
          (exercise) =>
              _exerciseQuery.isEmpty ||
              '${exercise.name} ${exercise.primaryMuscle} ${exercise.group}'
                  .toLowerCase()
                  .contains(_exerciseQuery),
        )
        .toList();
    if (exercises.isEmpty) {
      return const Center(
        child: _EmptyTraining(
          text: 'No encontramos ejercicios con ese nombre.',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final selected = _selectedExercises.contains(exercise.slug);
        return _ExerciseRow(
          exercise: exercise,
          selectionMode: _selectionMode,
          selected: selected,
          onToggle: () => _toggleExercise(exercise),
          onTap: _selectionMode ? () => _toggleExercise(exercise) : null,
        );
      },
    );
  }

  Widget _buildMyRoutines(TrainingProvider training, List<WorkoutDay> plan) {
    final catalog = _catalogRoutines(training.exercises);
    final byId = {
      ..._routineCache,
      for (final routine in catalog) routine.id: routine,
    };
    final weeklyById = {
      for (final day in plan)
        'weekly:${day.date}': _TrainingRoutine.fromWorkoutDay(day),
    };
    final saved = _savedRoutineIds
        .map((id) => byId[id] ?? weeklyById[id])
        .whereType<_TrainingRoutine>()
        .toList();
    final created = _createdRoutines.entries.map((entry) {
      final exercises = entry.value
          .map((id) => _exerciseCache[id])
          .whereType<Exercise>()
          .toList();
      return _TrainingRoutine(
        id: 'created:${entry.key}',
        name: entry.key,
        group: exercises.isEmpty
            ? 'Personalizada'
            : _groupLabel(exercises.first.muscleCategory),
        level: 'Personalizada',
        durationMinutes: (exercises.length * 5).clamp(10, 90).toInt(),
        calories: exercises.length * 30,
        exercises: exercises,
        isCreated: true,
      );
    }).toList();

    if (training.isLoading &&
        training.exercises.isEmpty &&
        saved.isEmpty &&
        created.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (saved.isEmpty && created.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: _EmptyTraining(
            text: 'Aquí aparecerán tus rutinas favoritas y las que crees desde Ejercicios.',
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        if (created.isNotEmpty) ...[
          const _SectionTitle(title: 'Rutinas creadas'),
          ...created.map(
            (routine) => _RoutineCard(
              routine: routine,
              showDelete: true,
              onDelete: () => _deleteCreatedRoutine(routine.name),
              onTap: () => _openRoutine(routine),
            ),
          ),
        ],
        if (saved.isNotEmpty) ...[
          const _SectionTitle(title: 'Rutinas guardadas'),
          ...saved.map(
            (routine) => _RoutineCard(
              routine: routine,
              isSaved: true,
              onTap: () => _openRoutine(routine),
              onSave: () => _toggleSaved(routine.id),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionActions() {
    if (!_selectionMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _selectionMode = true),
            icon: const Icon(Icons.add),
            label: const Text('Crear rutina'),
            style: _primaryButtonStyle(),
          ),
        ),
      );
    }
    if (_selectedExercises.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _cancelRoutineCreation,
            icon: const Icon(Icons.close),
            label: const Text('Cancelar creación'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelRoutineCreation,
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _showCreateRoutineDialog,
              icon: const Icon(Icons.save_outlined),
              label: Text('Crear rutina (${_selectedExercises.length})'),
              style: _primaryButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExercise(Exercise exercise) {
    if (exercise.slug.isEmpty) return;
    setState(() {
      if (!_selectionMode) _selectionMode = true;
      if (_selectedExercises.contains(exercise.slug)) {
        _selectedExercises.remove(exercise.slug);
      } else {
        _selectedExercises.add(exercise.slug);
      }
    });
  }

  void _cancelRoutineCreation() => setState(() {
    _selectionMode = false;
    _selectedExercises.clear();
  });

  Future<void> _showCreateRoutineDialog() async {
    final nameController = TextEditingController();
    final selected = _selectedExercises
        .map((id) => _exerciseCache[id])
        .whereType<Exercise>()
        .toList();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nombre de la rutina'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un nombre',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ejercicios seleccionados (${selected.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: selected.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: _ExerciseThumbnail(
                        url: selected[index].imageUrl,
                        size: 42,
                      ),
                      title: Text(
                        selected[index].name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = nameController.text.trim();
                if (value.isEmpty || selected.isEmpty) {
                  setDialogState(() {});
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              style: _primaryButtonStyle(),
              child: const Text('Crear rutina'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (!mounted || name == null) return;
    final normalized = name.trim();
    if (normalized.isEmpty || selected.isEmpty) return;
    if (_createdRoutines.containsKey(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe una rutina con ese nombre.')),
      );
      return;
    }
    setState(() {
      _createdRoutines[normalized] = selected
          .map((exercise) => exercise.slug)
          .toList();
      _selectionMode = false;
      _selectedExercises.clear();
      _tab = 2;
    });
    await _persistLocalRoutines();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rutina "$normalized" creada correctamente.')),
    );
  }

  Future<void> _deleteCreatedRoutine(String name) async {
    setState(() => _createdRoutines.remove(name));
    await _persistLocalRoutines();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Se eliminó la rutina "$name".')));
  }

  Future<void> _toggleSaved(String id) async {
    setState(() {
      if (!_savedRoutineIds.add(id)) _savedRoutineIds.remove(id);
    });
    await _persistLocalRoutines();
  }

  void _openRoutine(_TrainingRoutine routine) {
    if (_sessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hay una rutina activa. Reanúdala o termínala antes de abrir otra.',
          ),
        ),
      );
      return;
    }
    if (routine.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay ejercicios cargados para esta rutina. Vuelve a cargar el catálogo.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _selectedRoutine = routine;
      _detailTab = 0;
    });
  }

  Widget _buildRoutineDetails(_TrainingRoutine routine) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 14, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedRoutine = null),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver a rutinas',
                ),
                Expanded(
                  child: Text(
                    routine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleSaved(routine.id),
                  tooltip: _savedRoutineIds.contains(routine.id)
                      ? 'Quitar de guardadas'
                      : 'Guardar rutina',
                  icon: Icon(
                    _savedRoutineIds.contains(routine.id)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          _ExerciseHeroImage(
            url: routine.exercises.first.imageUrl,
            height: 180,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${routine.durationMinutes} min · ${routine.level}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${routine.exercises.length} ejercicios · ~${routine.calories} kcal',
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                _DifficultyBadge(level: routine.level),
                if (routine.workoutDay != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: routine.workoutDay!.completed
                        ? 'Marcar como pendiente'
                        : 'Marcar como completada',
                    onPressed: () =>
                        _toggleRoutineCompletion(routine.workoutDay!),
                    icon: Icon(
                      routine.workoutDay!.completed
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _DetailTab(
                  label: 'Ejercicios',
                  selected: _detailTab == 0,
                  onTap: () => setState(() => _detailTab = 0),
                ),
                _DetailTab(
                  label: 'Descripción',
                  selected: _detailTab == 1,
                  onTap: () => setState(() => _detailTab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _detailTab == 0
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    itemCount: routine.exercises.length,
                    itemBuilder: (_, index) => _ExerciseRow(
                      exercise: routine.exercises[index],
                      index: index + 1,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _InfoPanel(
                        title: 'Enfoque',
                        text:
                            'Rutina de ${routine.group.toLowerCase()} con ejercicios adaptados al catálogo de FitTrack.',
                      ),
                      const SizedBox(height: 10),
                      _InfoPanel(
                        title: 'Duración estimada',
                        text:
                            '${routine.durationMinutes} minutos incluyendo pausas entre series.',
                      ),
                      const SizedBox(height: 10),
                      const _InfoPanel(
                        title: 'Calorías estimadas',
                        text: 'El gasto aproximado depende del peso, ritmo e intensidad de cada persona.',
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: routine.exercises.isEmpty
                    ? null
                    : () => _startRoutine(routine),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Comenzar rutina'),
                style: _primaryButtonStyle(),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSession() {
    final routine = _selectedRoutine!;
    final exercise = routine.exercises[_exerciseIndex];
    final sets = exercise.sets > 0 ? exercise.sets : 3;
    final isResting = _awaitingContinue;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Ejercicio ${_exerciseIndex + 1} de ${routine.exercises.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Minimizar rutina',
                    onPressed: () => setState(() => _sessionMinimized = true),
                    icon: const Icon(Icons.picture_in_picture_alt),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                children: [
                  _ExerciseHeroImage(url: exercise.imageUrl, height: 210),
                  const SizedBox(height: 14),
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Objetivo: ${exercise.recommendedRepetitions} repeticiones',
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 12),
                  _CurrentSeriesCard(
                    current: _setNumber,
                    total: sets,
                    repetitions: exercise.recommendedRepetitions,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: .5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isResting ? 'Descanso' : 'Tiempo de serie',
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isResting
                              ? '${_restSeconds}s'
                              : _formatTime(_elapsedSeconds),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (isResting && _restSeconds == 0)
                          const Text(
                            'Descanso terminado. Continúa cuando estés listo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    title: 'Cómo hacerlo',
                    text: exercise.description.isNotEmpty
                        ? exercise.description
                        : exercise.technique,
                  ),
                  const SizedBox(height: 10),
                  _InstructionsPanel(
                    instructions: exerciseInstructionsInSpanish(exercise),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _savingCompletion
                          ? null
                          : _sessionComplete
                          ? _finishRoutine
                          : isResting
                          ? _continueSession
                          : _sessionPaused
                          ? _togglePause
                          : _finishSet,
                      icon: Icon(
                        _sessionComplete
                            ? Icons.check
                            : isResting || _sessionPaused
                            ? Icons.skip_next
                            : Icons.stop_circle_outlined,
                      ),
                      label: Text(
                        _savingCompletion
                            ? 'Guardando entrenamiento…'
                            : _sessionComplete
                            ? 'Finalizar rutina'
                            : isResting
                            ? 'Continuar'
                            : _sessionPaused
                            ? 'Reanudar'
                            : 'Terminé la serie',
                      ),
                      style: _primaryButtonStyle(),
                    ),
                  ),
                  if (!_sessionComplete) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _togglePause,
                            icon: Icon(
                              _sessionPaused ? Icons.play_arrow : Icons.pause,
                            ),
                            label: Text(_sessionPaused ? 'Reanudar' : 'Pausar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: _confirmFinishRoutine,
                            child: const Text('Terminar rutina'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startRoutine(_TrainingRoutine routine) {
    _sessionTicker?.cancel();
    setState(() {
      _selectedRoutine = routine;
      _sessionActive = true;
      _sessionMinimized = false;
      _sessionPaused = false;
      _sessionComplete = false;
      _awaitingContinue = false;
      _exerciseIndex = 0;
      _setNumber = 1;
      _elapsedSeconds = 0;
      _sessionElapsedSeconds = 0;
      _restSeconds = 0;
    });
    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_sessionActive || _sessionPaused || _sessionComplete) {
        return;
      }
      setState(() {
        _sessionElapsedSeconds++;
        if (_awaitingContinue) {
          if (_restSeconds > 0) _restSeconds--;
        } else {
          _elapsedSeconds++;
        }
      });
    });
  }

  void _togglePause() => setState(() => _sessionPaused = !_sessionPaused);

  void _finishSet() => setState(() {
    _sessionPaused = false;
    _awaitingContinue = true;
    _restSeconds = 60;
  });

  void _continueSession() {
    final routine = _selectedRoutine;
    if (routine == null) return;
    setState(() {
      _restSeconds = 0;
      _sessionPaused = false;
      _awaitingContinue = false;
      final current = routine.exercises[_exerciseIndex];
      final sets = current.sets > 0 ? current.sets : 3;
      if (_setNumber < sets) {
        _setNumber++;
        _elapsedSeconds = 0;
      } else if (_exerciseIndex + 1 < routine.exercises.length) {
        _exerciseIndex++;
        _setNumber = 1;
        _elapsedSeconds = 0;
      } else {
        _sessionComplete = true;
      }
    });
  }

  void _confirmFinishRoutine() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Terminar rutina?'),
      content: const Text('El cronómetro se detendrá y cerrarás la sesión.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Seguir entrenando'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _finishRoutine();
          },
          child: const Text('Terminar'),
        ),
      ],
    ),
  );

  Future<void> _finishRoutine() async {
    final routine = _selectedRoutine;
    final token = context.read<AuthProvider>().sessionToken;
    final progressProvider = context.read<ProgressProvider>();
    final appStateProvider = context.read<AppStateProvider>();
    final completed = _sessionComplete;
    if (completed && routine != null && token != null) {
      setState(() => _savingCompletion = true);
      try {
        await context.read<TrainingProvider>().recordCompletedSession(
          token: token,
          routineName: routine.name,
          durationSeconds: _sessionElapsedSeconds > 0
              ? _sessionElapsedSeconds
              : 1,
          performedOn: _dateKey(DateTime.now()),
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _savingCompletion = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el entrenamiento. Inténtalo nuevamente.',
            ),
          ),
        );
        return;
      }
      try {
        await Future.wait<void>([
          progressProvider.load(token, forceRefresh: true),
          appStateProvider.loadRemoteTraining(token),
        ]);
      } catch (_) {
        // El registro ya quedó guardado en el servidor. Un fallo al actualizar
        // los resúmenes no debe provocar que se envíe una sesión duplicada.
      }
    }
    _sessionTicker?.cancel();
    final minutes = (_sessionElapsedSeconds / 60).round().clamp(1, 1440);
    setState(() {
      _sessionActive = false;
      _sessionMinimized = false;
      _sessionPaused = false;
      _sessionComplete = false;
      _savingCompletion = false;
      _awaitingContinue = false;
      _selectedRoutine = null;
    });
    if (completed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Rutina completada! Se registraron $minutes min de entrenamiento.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleRoutineCompletion(WorkoutDay day) async {
    final token = context.read<AuthProvider>().sessionToken;
    if (token != null) {
      await context.read<TrainingProvider>().toggleDay(token, day);
    }
  }

  String _groupFromText(String text) {
    final value = text.toLowerCase();
    if (value.contains('biceps') || value.contains('bíceps')) return 'biceps';
    if (value.contains('triceps') || value.contains('tríceps')) {
      return 'triceps';
    }
    if (value.contains('hombro') || value.contains('shoulder')) {
      return 'hombros';
    }
    if (value.contains('espalda') || value.contains('back')) return 'espalda';
    if (value.contains('pecho') || value.contains('chest')) return 'pecho';
    if (value.contains('abdomen') || value.contains('core')) return 'abdomen';
    if (value.contains('pierna') ||
        value.contains('leg') ||
        value.contains('glúte')) {
      return 'pierna';
    }
    return 'general';
  }

  String _groupLabel(String key) => switch (key) {
    'biceps' || 'triceps' || 'brazos' => 'Brazos',
    'pierna' => 'Piernas',
    'hombros' => 'Hombros',
    'espalda' => 'Espalda',
    'pecho' => 'Pecho',
    'abdomen' => 'Abdomen',
    _ => 'General',
  };

  String _legacyMuscleId(String key) => switch (key) {
    'pierna' => 'quadriceps',
    'espalda' => 'lats',
    'abdomen' => 'abdominals',
    'hombros' => 'shoulders',
    'pecho' => 'chest',
    _ => key,
  };

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(vertical: 14),
    textStyle: const TextStyle(fontWeight: FontWeight.w800),
  );
}

class _TrainingRoutine {
  const _TrainingRoutine({
    required this.id,
    required this.name,
    required this.group,
    required this.level,
    required this.durationMinutes,
    required this.calories,
    required this.exercises,
    this.isCreated = false,
    this.workoutDay,
  });

  factory _TrainingRoutine.fromWorkoutDay(WorkoutDay day) => _TrainingRoutine(
    id: 'weekly:${day.date}',
    name: day.title,
    group: day.muscleGroup,
    level: day.exercises.isEmpty
        ? 'Intermedio'
        : _levelLabel(day.exercises.first.level),
    durationMinutes: day.durationMinutes,
    calories: day.durationMinutes * 6,
    exercises: day.exercises,
    workoutDay: day,
  );

  final String id;
  final String name;
  final String group;
  final String level;
  final int durationMinutes;
  final int calories;
  final List<Exercise> exercises;
  final bool isCreated;
  final WorkoutDay? workoutDay;
}

String _normalizedLevel(String level) {
  final value = level.toLowerCase();
  if (value.contains('begin') || value.contains('princip')) return 'beginner';
  if (value.contains('expert') ||
      value.contains('advanced') ||
      value.contains('avanz')) {
    return 'expert';
  }
  return 'intermediate';
}

String _levelLabel(String level) => switch (_normalizedLevel(level)) {
  'beginner' => 'Principiante',
  'expert' => 'Avanzado',
  _ => 'Intermedio',
};

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 56,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 90,
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
    ),
  );
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.onTap,
    this.onSave,
    this.onDelete,
    this.onComplete,
    this.isSaved = false,
    this.showDelete = false,
    this.completed = false,
  });
  final _TrainingRoutine routine;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;
  final bool isSaved;
  final bool showDelete;
  final bool completed;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF1E342B)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Row(
        children: [
          _ExerciseThumbnail(
            url: routine.exercises.isEmpty
                ? null
                : routine.exercises.first.imageUrl,
            size: 112,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${routine.group} · ${routine.exercises.length} ejercicios',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${routine.durationMinutes} min · ~${routine.calories} kcal',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _DifficultyBadge(level: routine.level),
                ],
              ),
            ),
          ),
          if (onComplete != null)
            IconButton(
              tooltip: completed
                  ? 'Rutina completada'
                  : 'Marcar rutina completada',
              onPressed: onComplete,
              icon: Icon(
                completed ? Icons.check_circle : Icons.check_circle_outline,
                color: AppColors.primary,
              ),
            )
          else if (showDelete)
            IconButton(
              tooltip: 'Eliminar rutina',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            )
          else if (onSave != null)
            IconButton(
              tooltip: isSaved
                  ? 'Quitar de mis rutinas'
                  : 'Guardar en mis rutinas',
              onPressed: onSave,
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: AppColors.primary,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: AppColors.mutedText),
            ),
        ],
      ),
    ),
  );
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.level});
  final String level;
  @override
  Widget build(BuildContext context) {
    final normalized = level.toLowerCase();
    final color = normalized.contains('princip')
        ? const Color(0xFFFFC107)
        : normalized.contains('avanz')
        ? const Color(0xFF9C83FF)
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CurrentSeriesCard extends StatelessWidget {
  const _CurrentSeriesCard({
    required this.current,
    required this.total,
    required this.repetitions,
  });

  final int current;
  final int total;
  final String repetitions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF063B2E),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.primary, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .14),
          blurRadius: 15,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: AppColors.primary, size: 22),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'SERIE ACTUAL',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Text(
              '$current de $total',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : current / total,
            minHeight: 8,
            backgroundColor: const Color(0xFF17372B),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa $repetitions repeticiones y registra el fin de la serie.',
          style: const TextStyle(color: AppColors.text, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    this.index,
    this.selectionMode = false,
    this.selected = false,
    this.onToggle,
    this.onTap,
  });
  final Exercise exercise;
  final int? index;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: selected
          ? const Color(0xFF0E3024)
          : AppColors.surface.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: selected ? AppColors.primary : const Color(0xFF1D3028),
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap:
          onTap ??
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ExerciseDetailScreen(exercise: exercise),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          children: [
            _ExerciseThumbnail(url: exercise.imageUrl, size: 78, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    index == null ? exercise.name : '$index. ${exercise.name}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${exercise.primaryMuscle.isEmpty ? exercise.muscleCategory : exercise.primaryMuscle} · ${exercise.sets} series × ${exercise.recommendedRepetitions} repeticiones',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DifficultyBadge(level: _levelLabel(exercise.level)),
                  if (exercise.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selectionMode)
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle?.call(),
                activeColor: AppColors.primary,
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right, color: AppColors.mutedText),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({this.url, this.size = 80, this.radius = 12});
  final String? url;
  final double size;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox(
      width: size,
      height: size,
      child: url == null || url!.isEmpty
          ? const _ImageFallback()
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ImageFallback(),
            ),
    ),
  );
}

class _ExerciseHeroImage extends StatelessWidget {
  const _ExerciseHeroImage({this.url, required this.height});
  final String? url;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: url == null || url!.isEmpty
        ? const _ImageFallback(iconSize: 54)
        : Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _ImageFallback(iconSize: 54),
          ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.iconSize = 30});
  final double iconSize;
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF15231D),
    child: Center(
      child: Icon(
        Icons.fitness_center,
        color: AppColors.primary,
        size: iconSize,
      ),
    ),
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: .48),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFF21352D)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
          text,
          style: const TextStyle(color: AppColors.mutedText, height: 1.35),
        ),
      ],
    ),
  );
}

class _InstructionsPanel extends StatelessWidget {
  const _InstructionsPanel({required this.instructions});
  final List<String> instructions;
  @override
  Widget build(BuildContext context) => _InfoPanel(
    title: 'Pasos de ejecución',
    text: instructions
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n\n'),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});
  final PersonalizedRecommendation recommendation;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF063B2E),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.primary.withValues(alpha: .45)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recomendación ${recommendation.generatedBy == 'gemini' ? 'de Gemini' : 'FITTRACK'}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          recommendation.trainingTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          recommendation.trainingSummary,
          style: const TextStyle(color: AppColors.mutedText),
        ),
        ...recommendation.safetyNotes
            .take(3)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('• $item', style: const TextStyle(fontSize: 12)),
              ),
            ),
      ],
    ),
  );
}

class _EmptyTraining extends StatelessWidget {
  const _EmptyTraining({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: .4),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.mutedText),
    ),
  );
}
