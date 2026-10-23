import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../repositories/exercise_repository.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _repository = ExerciseRepository();
  late final Future<List<Exercise>> _exercises = _repository.load();
  final _muscles = const {
    'Todos': '',
    'Brazos': 'biceps',
    'Piernas': 'quadriceps',
    'Espalda': 'lats',
    'Abdomen': 'abdominals',
    'Hombros': 'shoulders',
    'Pecho': 'chest',
  };
  String _muscle = 'Todos';
  String _search = '';
  int _tab = 0;
  Set<String> _saved = {};
  _Routine? _selectedRoutine;
  bool _session = false;
  bool _sessionMinimized = false;
  final Map<String, List<String>> _created = {};
  bool _creatingRoutine = false;
  final Set<String> _selectedExerciseIds = {};
  final _routineNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final preferences = await SharedPreferences.getInstance();
    final rawCreated = preferences.getString('training.created');
    final decoded = rawCreated == null
        ? <String, dynamic>{}
        : (jsonDecode(rawCreated) as Map<String, dynamic>);
    if (mounted) {
      setState(() {
        _saved = (preferences.getStringList('training.saved') ?? []).toSet();
        _created
          ..clear()
          ..addAll(
            decoded.map(
              (name, ids) =>
                  MapEntry(name, (ids as List).whereType<String>().toList()),
            ),
          );
      });
    }
  }

  Future<void> _toggleSaved(String id) async {
    setState(() => _saved.contains(id) ? _saved.remove(id) : _saved.add(id));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('training.saved', _saved.toList());
  }

  @override
  void dispose() {
    _routineNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session && _selectedRoutine != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Offstage(
              offstage: _sessionMinimized,
              child: _sessionPage(_selectedRoutine!),
            ),
          ),
          if (_sessionMinimized) ...[
            _catalog(),
            Positioned(
              right: 14,
              top: 8,
              child: SafeArea(
                child: ActionChip(
                  avatar: const Icon(Icons.timer, color: AppColors.primary),
                  label: const Text('Rutina activa'),
                  onPressed: () => setState(() => _sessionMinimized = false),
                ),
              ),
            ),
          ],
        ],
      );
    }
    return _selectedRoutine == null
        ? _catalog()
        : _routineDetail(_selectedRoutine!);
  }

  Widget _catalog() => DefaultTabController(
    length: 3,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'El esfuerzo de hoy es el éxito de mañana.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
            ),
          ),
          TabBar(
            onTap: (index) => setState(() => _tab = index),
            tabs: const [
              Tab(text: 'Rutinas'),
              Tab(text: 'Ejercicios'),
              Tab(text: 'Mis rutinas'),
            ],
          ),
          if (_tab < 2)
            SizedBox(
              height: 56,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                children: _muscles.keys
                    .map(
                      (name) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(name),
                          selected: _muscle == name,
                          onSelected: (_) => setState(() => _muscle = name),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _exercises,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(
                    child: Text(
                      'No se pudo cargar el catálogo de ejercicios.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  );
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final filtered = snapshot.data!
                    .where(_matches)
                    .where(
                      (exercise) =>
                          _tab != 1 ||
                          _search.isEmpty ||
                          exercise.name.toLowerCase().contains(
                            _search.toLowerCase(),
                          ),
                    )
                    .toList();
                return switch (_tab) {
                  0 => _routineList(filtered),
                  1 => _exerciseList(filtered),
                  _ => _myRoutines(snapshot.data!),
                };
              },
            ),
          ),
        ],
      ),
    ),
  );

  bool _matches(Exercise exercise) {
    final muscle = _muscles[_muscle] ?? '';
    return muscle.isEmpty || exercise.muscles.contains(muscle);
  }

  List<_Routine> _routinesFor(List<Exercise> exercises) {
    final groups = _muscle == 'Todos' ? _muscles.keys.skip(1) : [_muscle];
    final routines = <_Routine>[];
    for (final group in groups) {
      for (final level in ['beginner', 'intermediate', 'expert']) {
        final exercisesForRoutine = exercises
            .where(
              (exercise) =>
                  exercise.level == level &&
                  exercise.muscles.contains(_muscles[group]),
            )
            .take(5)
            .toList();
        if (exercisesForRoutine.isNotEmpty) {
          routines.add(
            _Routine(
              id: '${_muscles[group]}_$level',
              name: 'Rutina de $group',
              muscle: group,
              level: level,
              exercises: exercisesForRoutine,
            ),
          );
        }
      }
    }
    return routines;
  }

  Widget _routineList(List<Exercise> exercises) {
    final routines = _routinesFor(exercises);
    return ListView.builder(
      key: const PageStorageKey('routine-catalog'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: routines.length,
      itemBuilder: (context, index) => _routineCard(routines[index]),
    );
  }

  Widget _routineCard(_Routine routine, {bool canDelete = false}) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => setState(() {
        _selectedRoutine = routine;
        _session = false;
      }),
      child: SizedBox(
        height: 136,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 128,
                height: 136,
                child: _exerciseImage(routine.exercises.first),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      routine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fuerza · ' +
                          routine.exercises.length.toString() +
                          ' ejercicios',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _duration(routine).toString() + ' min · ~150 kcal',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _difficultyColor(routine.level)
                            .withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _difficulty(routine.level),
                        style: TextStyle(
                          color: _difficultyColor(routine.level),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: canDelete ? 'Eliminar rutina' : 'Guardar rutina',
              icon: Icon(
                canDelete
                    ? Icons.delete_outline
                    : _saved.contains(routine.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: canDelete ? AppColors.mutedText : AppColors.primary,
              ),
              onPressed: canDelete
                  ? () => _deleteRoutine(routine.id)
                  : () => _toggleSaved(routine.id),
            ),
          ],
        ),
      ),
    ),
  );
  Color _difficultyColor(String level) => switch (level) {
    'beginner' => const Color(0xFFFFC107),
    'intermediate' => const Color(0xFF00E676),
    'expert' => const Color(0xFF8B80FF),
    _ => AppColors.primary,
  };

  String _difficulty(String level) => switch (level) {
    'beginner' => 'Principiante',
    'intermediate' => 'Intermedio',
    'expert' => 'Avanzado',
    _ => 'Principiante',
  };
  Widget _exerciseImage(Exercise exercise, {BoxFit fit = BoxFit.cover}) =>
      exercise.imageUrl.isEmpty
      ? Container(
          color: AppColors.surface,
          alignment: Alignment.center,
          child: const Icon(
            Icons.fitness_center,
            size: 42,
            color: AppColors.primary,
          ),
        )
      : Image.network(
          exercise.imageUrl,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surface,
            alignment: Alignment.center,
            child: const Icon(
              Icons.fitness_center,
              size: 42,
              color: AppColors.primary,
            ),
          ),
        );

  Widget _routineDetail(_Routine routine) => SafeArea(
    child: Column(
      children: [
        ListTile(
          leading: IconButton(
            onPressed: () => setState(() => _selectedRoutine = null),
            tooltip: 'Volver a rutinas',
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            routine.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${_duration(routine)} min · ${_level(routine.level)}',
            style: const TextStyle(color: AppColors.primary),
          ),
        ),
        SizedBox(
          height: 170,
          width: double.infinity,
          child: _exerciseImage(routine.exercises.first),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => setState(() => _session = true),
              child: const Text('Comenzar rutina'),
            ),
          ),
        ),
        DefaultTabController(
          length: 2,
          child: Expanded(
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Ejercicios'),
                    Tab(text: 'Descripción'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                        itemCount: routine.exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = routine.exercises[index];
                          return Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 86,
                                  height: 56,
                                  child: _exerciseImage(exercise),
                                ),
                              ),
                              title: Text(
                                _title(exercise.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: const Text('3 × 12 repeticiones'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showExerciseDialog(exercise),
                            ),
                          );
                        },
                      ),
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            routine.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Rutina de ${routine.muscle.toLowerCase()} con ${routine.exercises.length} ejercicios. Nivel ${_level(routine.level).toLowerCase()}, duración aproximada ${_duration(routine)} minutos y gasto estimado de 150 kcal.',
                            style: const TextStyle(height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'La duración y las calorías son estimaciones; dependen del ritmo, descansos y características de cada persona.',
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sessionPage(_Routine routine) => _RoutineSession(
    routine: routine,
    onBack: () => setState(() => _sessionMinimized = true),
    onFinish: () => setState(() {
      _session = false;
      _selectedRoutine = null;
    }),
  );

  Future<void> _showExerciseDialog(Exercise exercise) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(_title(exercise.name)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 170,
                width: double.infinity,
                child: _exerciseImage(exercise),
              ),
              const SizedBox(height: 12),
              Text(
                'Músculos: ' + exercise.muscles.map(_muscleLabel).join(', '),
              ),
              Text('Dificultad: ' + _difficulty(exercise.level)),
              const SizedBox(height: 12),
              const Text(
                'Cómo hacerlo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ..._exerciseGuide(exercise).asMap().entries.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text((step.key + 1).toString() + '. ' + step.value),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  Widget _exerciseList(List<Exercise> exercises) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: TextField(
          onChanged: (value) => setState(() => _search = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar ejercicios',
          ),
        ),
      ),
      if (_creatingRoutine)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedExerciseIds.length.toString() +
                      ' ejercicios seleccionados',
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ),
              TextButton.icon(
                onPressed: _cancelRoutineCreation,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      Expanded(
        child: Stack(
          children: [
            ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                if (_creatingRoutine)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Selecciona los ejercicios que quieres incluir.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  ),
                ...exercises.map(
                  (exercise) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: _exerciseImage(exercise),
                        ),
                      ),
                      title: Text(
                        _title(exercise.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        exercise.muscles.map(_muscleLabel).join(', ') +
                            ' · ' +
                            _difficulty(exercise.level) +
                            '\n3 series × 12 repeticiones',
                      ),
                      trailing: _creatingRoutine
                          ? Checkbox(
                              value: _selectedExerciseIds.contains(exercise.id),
                              onChanged: (_) =>
                                  _toggleExerciseSelection(exercise.id),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _creatingRoutine
                          ? () => _toggleExerciseSelection(exercise.id)
                          : () => _showExerciseDialog(exercise),
                    ),
                  ),
                ),
              ],
            ),
            if (!_creatingRoutine)
              Positioned(
                left: 20,
                right: 20,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: FilledButton.icon(
                    onPressed: () => setState(() {
                      _creatingRoutine = true;
                      _selectedExerciseIds.clear();
                      _routineNameController.clear();
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear rutina'),
                  ),
                ),
              ),
            if (_creatingRoutine && _selectedExerciseIds.isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: FilledButton.icon(
                    onPressed: _askRoutineName,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continuar'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
  void _cancelRoutineCreation() {
    setState(() {
      _creatingRoutine = false;
      _selectedExerciseIds.clear();
      _routineNameController.clear();
    });
  }

  void _toggleExerciseSelection(String id) {
    setState(() {
      if (!_selectedExerciseIds.add(id)) _selectedExerciseIds.remove(id);
    });
  }

  Future<void> _askRoutineName() async {
    final selectedExercises = (await _exercises)
        .where((exercise) => _selectedExerciseIds.contains(exercise.id))
        .toList();
    if (!mounted) return;
    _routineNameController.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: const Text('Nombre de la rutina'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _routineNameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un nombre',
                  ),
                  onChanged: (_) => updateDialog(() {}),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ejercicios seleccionados (' +
                      selectedExercises.length.toString() +
                      ')',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: selectedExercises.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exercise = selectedExercises[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _title(exercise.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          exercise.muscles.map(_muscleLabel).join(', ') +
                              ' · 3 series × 12 repeticiones',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
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
              onPressed: _routineNameController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                      dialogContext,
                      _routineNameController.text.trim(),
                    ),
              child: const Text('Crear rutina'),
            ),
          ],
        ),
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    await _saveCreatedRoutine(name.trim());
  }

  Future<void> _saveCreatedRoutine(String name) async {
    if (_selectedExerciseIds.isEmpty) return;
    if (_created.containsKey(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe una rutina con ese nombre.')),
      );
      return;
    }
    setState(() {
      _created[name] = _selectedExerciseIds.toList();
      _creatingRoutine = false;
      _selectedExerciseIds.clear();
      _routineNameController.clear();
      _tab = 1;
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('training.created', jsonEncode(_created));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rutina ' + name + ' creada correctamente')),
      );
    }
  }

  Future<void> _deleteRoutine(String id) async {
    setState(() => _created.remove(id));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('training.created', jsonEncode(_created));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Rutina ' + id + ' eliminada')));
    }
  }

  List<String> _exerciseGuide(Exercise exercise) {
    final muscles = exercise.muscles.map(_muscleLabel).join(', ');
    final equipment = switch (exercise.equipment.toLowerCase()) {
      'body only' || 'body weight' => 'tu propio peso corporal',
      'dumbbell' || 'dumbbells' => 'mancuernas',
      'barbell' => 'una barra',
      'cable' => 'la polea',
      'machine' => 'la máquina indicada',
      'bands' => 'una banda elástica',
      _ => exercise.equipment,
    };
    return [
      'Prepara ' +
          equipment +
          ' y colócate en una posición estable. Mantén la espalda alineada y activa los músculos de ' +
          muscles.toLowerCase() +
          '.',
      'Realiza el movimiento de forma controlada, con un recorrido cómodo y sin rebotes. Evita contener la respiración.',
      'Regresa despacio a la posición inicial y conserva el control durante toda la repetición. Si sientes dolor, detén el ejercicio.',
    ];
  }

  String _muscleLabel(String muscle) => switch (muscle) {
    'biceps' => 'Bíceps',
    'triceps' => 'Tríceps',
    'quadriceps' => 'Cuádriceps',
    'hamstrings' => 'Isquiotibiales',
    'abdominals' => 'Abdomen',
    'shoulders' => 'Hombros',
    'chest' => 'Pecho',
    'lats' => 'Espalda',
    'glutes' => 'Glúteos',
    'calves' => 'Pantorrillas',
    _ => muscle,
  };
  Widget _myRoutines(List<Exercise> all) {
    final routines = _routinesFor(all)
        .where((routine) => _saved.contains(routine.id))
        .toList();
    final created = _created.entries
        .map(
          (entry) => _Routine(
            id: entry.key,
            name: entry.key,
            muscle: 'Personalizada',
            level: 'beginner',
            exercises: all
                .where((exercise) => entry.value.contains(exercise.id))
                .toList(),
          ),
        )
        .toList();
    final items = [...routines, ...created];
    if (items.isEmpty)
      return const Center(
        child: Text('Guarda una rutina o crea la tuya desde Ejercicios.'),
      );
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: items.length,
      itemBuilder: (_, index) => _routineCard(
        items[index],
        canDelete: _created.containsKey(items[index].id),
      ),
    );
  }

  int _duration(_Routine routine) => routine.exercises.length * 5;
  String _level(String level) => switch (level) {
    'beginner' => 'Nivel principiante',
    'intermediate' => 'Nivel intermedio',
    'expert' => 'Nivel avanzado',
    _ => 'Nivel principiante',
  };
  String _title(String value) {
    final normalized = value.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    const translations = <String, String>{
      '3/4 Sit-Up': 'Abdominales parciales',
      '90/90 Hamstring': 'Estiramiento de isquiotibiales 90/90',
      'Barbell Bench Press': 'Press de banca con barra',
      'Bench Press': 'Press de banca',
      'Push Up': 'Flexiones de brazos',
      'Push-Up': 'Flexiones de brazos',
      'Pull Up': 'Dominadas',
      'Pull-Up': 'Dominadas',
      'Squat': 'Sentadilla',
      'Barbell Squat': 'Sentadilla con barra',
      'Dumbbell Lateral Raise': 'Elevación lateral con mancuernas',
      'Plank': 'Plancha',
      'Crunch': 'Abdominal corto',
      'Dumbbell Bicep Curl': 'Curl de bíceps con mancuernas',
      'Triceps Pushdown': 'Extensión de tríceps en polea',
      'Deadlift': 'Peso muerto',
      'Lunge': 'Zancada',
    };
    return translations[value] ??
        normalized
            .replaceAll('Barbell', 'con barra')
            .replaceAll('Dumbbell', 'con mancuernas')
            .replaceAll('Cable', 'en polea')
            .replaceAll('Machine', 'en máquina')
            .replaceAll('Bench Press', 'Press de banca')
            .replaceAll('Incline', 'inclinado')
            .replaceAll('Decline', 'declinado')
            .replaceAll('Standing', 'de pie')
            .replaceAll('Seated', 'sentado')
            .replaceAll('Lying', 'acostado')
            .replaceAll('Leg Extension', 'extensión de piernas')
            .replaceAll('Leg Curl', 'curl de piernas')
            .replaceAll('Leg Raise', 'elevación de piernas')
            .replaceAll('Lateral Raise', 'elevación lateral')
            .replaceAll('Front Raise', 'elevación frontal')
            .replaceAll('Rear Delt', 'deltoides posterior')
            .replaceAll('Triceps', 'tríceps')
            .replaceAll('Biceps', 'bíceps')
            .replaceAll('Shoulder', 'hombro')
            .replaceAll('Chest', 'pecho')
            .replaceAll('Squat', 'sentadilla')
            .replaceAll('Deadlift', 'peso muerto')
            .replaceAll('Lunge', 'zancada')
            .replaceAll('Row', 'remo')
            .replaceAll('Curl', 'curl')
            .replaceAll('Crunch', 'abdominal')
            .replaceAll('Plank', 'plancha')
            .replaceAll('Pull Up', 'dominada')
            .replaceAll('Push Up', 'flexión de brazos');
  }
}

class _Routine {
  const _Routine({
    required this.id,
    required this.name,
    required this.muscle,
    required this.level,
    required this.exercises,
  });
  final String id, name, muscle, level;
  final List<Exercise> exercises;
}

class _RoutineSession extends StatefulWidget {
  const _RoutineSession({
    required this.routine,
    required this.onBack,
    required this.onFinish,
  });
  final _Routine routine;
  final VoidCallback onBack, onFinish;
  @override
  State<_RoutineSession> createState() => _RoutineSessionState();
}

class _RoutineSessionState extends State<_RoutineSession> {
  Timer? _timer;
  int _seconds = 0, _rest = 0, _set = 1, _exercise = 0;
  bool _running = false;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_rest > 0) {
          _rest--;
          if (_rest == 0) {
            if (_set < 3) {
              _set++;
            } else {
              _exercise++;
              _set = 1;
            }
          }
        } else if (_running) {
          _seconds++;
        }
      });
      if (_rest == 0 && !_running) _timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = _exercise >= widget.routine.exercises.length;
    final current = finished ? null : widget.routine.exercises[_exercise];
    return SafeArea(
      child: Column(
        children: [
          ListTile(
            leading: IconButton(
              onPressed: widget.onBack,
              tooltip: 'Minimizar contador',
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
            title: Text(widget.routine.name),
            trailing: TextButton(
              onPressed: widget.onFinish,
              child: const Text('Terminar'),
            ),
            subtitle: Text(
              'Ejercicio ${finished ? widget.routine.exercises.length : _exercise + 1} de ${widget.routine.exercises.length}',
            ),
          ),
          if (finished)
            const Expanded(child: Center(child: Text('¡Rutina completada!')))
          else ...[
            SizedBox(
              height: 200,
              width: double.infinity,
              child: current == null
                  ? const SizedBox()
                  : Image.network(
                      current.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fitness_center, size: 56),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              _rest > 0 ? 'Descanso' : 'Serie $_set de 3',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              _rest > 0
                  ? '${_rest}s'
                  : '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            if (current != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Mantén la espalda alineada, controla cada repetición y respira durante el movimiento. Si sientes dolor, detén el ejercicio.',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_rest > 0) {
                      _timer?.cancel();
                      setState(() {
                        _rest = 0;
                        if (_set < 3) {
                          _set++;
                        } else {
                          _exercise++;
                          _set = 1;
                        }
                      });
                      return;
                    }
                    if (_running) {
                      _timer?.cancel();
                      setState(() {
                        _running = false;
                        _rest = 60;
                      });
                      _tick();
                    } else {
                      setState(() => _running = true);
                      _tick();
                    }
                  },
                  child: Text(
                    _rest > 0
                        ? 'Continuar'
                        : _running
                        ? 'Terminé la serie'
                        : 'Iniciar serie',
                  ),
                ),
              ),
            ),
          ],
          if (finished)
            FilledButton(
              onPressed: widget.onFinish,
              child: const Text('Finalizar rutina'),
            ),
        ],
      ),
    );
  }
}
