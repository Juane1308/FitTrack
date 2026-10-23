import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/training_repository.dart';

enum TrainingLoadStatus { idle, loading, ready, error }

class TrainingProvider extends ChangeNotifier {
  TrainingProvider({ExerciseRepository? repository, TrainingRepository? trainingRepository})
    : _repository = repository ?? ExerciseRepository(),
      _trainingRepository = trainingRepository ?? TrainingRepository();

  final ExerciseRepository _repository;
  final TrainingRepository _trainingRepository;
  TrainingLoadStatus _status = TrainingLoadStatus.idle;
  List<Exercise> _exercises = const [];
  String? _errorMessage;
  String _selectedGroup = 'all';
  String _selectedGoal = 'Mantenerme activo';
  List<WorkoutDay> _weeklyPlan = const [];
  bool _weekLoading = false;
  String? _weekError;

  TrainingLoadStatus get status => _status;
  List<Exercise> get exercises => _exercises;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == TrainingLoadStatus.loading;
  String get selectedGroup => _selectedGroup;
  String get selectedGoal => _selectedGoal;
  List<WorkoutDay> get weeklyPlan => _weeklyPlan;
  bool get weekLoading => _weekLoading;
  String? get weekError => _weekError;

  Future<void> loadWeeklyPlan(String token, {bool forceRefresh = false}) async {
    if (_weekLoading || (_weeklyPlan.isNotEmpty && !forceRefresh)) return;
    _weekLoading = true;
    _weekError = null;
    notifyListeners();
    try {
      _weeklyPlan = await _trainingRepository.fetchWeek(token);
    } catch (_) {
      _weekError = 'No se pudo generar tu rutina semanal.';
    } finally {
      _weekLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleDay(String token, WorkoutDay day) async {
    try {
      _weeklyPlan = await _trainingRepository.completeDay(token, day.date, !day.completed);
      notifyListeners();
    } catch (_) {
      _weekError = 'No se pudo actualizar el día de entrenamiento.';
      notifyListeners();
    }
  }

  Future<void> loadExercises({
    bool forceRefresh = false,
    String group = 'all',
    String goal = 'Mantenerme activo',
  }) async {
    if (_status == TrainingLoadStatus.loading ||
        (_status == TrainingLoadStatus.ready && !forceRefresh &&
            group == _selectedGroup && goal == _selectedGoal)) {
      return;
    }

    _selectedGroup = group;
    _selectedGoal = goal;

    _status = TrainingLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final exercises = await _repository.fetchExercises(
        group: group == 'all' ? null : group,
        goal: goal,
      );
      _exercises = exercises;
      _status = TrainingLoadStatus.ready;
      if (_exercises.isEmpty) {
        _errorMessage = 'No hay ejercicios reales disponibles para este filtro.';
      }
    } catch (_) {
      _exercises = const [];
      _status = TrainingLoadStatus.error;
      _errorMessage = 'No se pudo consultar el catálogo de ejercicios.';
    }
    notifyListeners();
  }

  Future<Exercise> loadDetails(Exercise exercise) {
    if (exercise.slug.isEmpty) return Future.value(exercise);
    return _repository.fetchExercise(exercise.slug);
  }

}
