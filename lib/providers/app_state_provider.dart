import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/profile_repository.dart';
import '../repositories/training_repository.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider({
    ProfileRepository? profileRepository,
    TrainingRepository? trainingRepository,
  })  : _profileRepository = profileRepository ?? ProfileRepository(),
        _trainingRepository = trainingRepository ?? TrainingRepository() {
    _dashboard = DashboardSummary.empty;
    _routines = const [];
  }

  final ProfileRepository _profileRepository;
  final TrainingRepository _trainingRepository;

  late DashboardSummary _dashboard;
  late List<Routine> _routines;

  UserProfile _profile = const UserProfile(
    goal: 'Definir objetivo',
    birthDate: null,
    weight: null,
    height: null,
    sport: '',
    trainingPlace: '',
    injuries: '',
    pain: '',
    surgeries: '',
    diseases: '',
    allergies: '',
  );
  UserProfile? _remoteProfile;

  UserProfile get profile => _profile;
  DashboardSummary get dashboard => _dashboard;
  List<Routine> get routines => _routines;
  List<Food> get foods => const [];
  List<Recipe> get recipes => const [];
  List<ProgressEntry> get progress => const [];

  bool get isProfileComplete =>
      _remoteProfile?.weight != null &&
      _remoteProfile?.height != null &&
      _remoteProfile?.goal != 'Definir objetivo';

  void updateProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  Future<UserProfile?> loadRemoteProfile(String token) async {
    final profile = await _profileRepository.fetchProfile(token);
    _remoteProfile = profile;
    if (profile != null) {
      _profile = profile;
      notifyListeners();
    }
    return profile;
  }

  Future<void> saveRemoteProfile(String token, UserProfile profile) async {
    _profile = await _profileRepository.saveProfile(token, profile);
    _remoteProfile = _profile;
    notifyListeners();
  }

  Future<void> loadRemoteTraining(String token) async {
    final week = await _trainingRepository.fetchWeek(token);
    final completedDays = week.where((day) => day.completed).length;
    WorkoutDay? activeDay;
    for (final day in week) {
      if (!day.completed) {
        activeDay = day;
        break;
      }
    }
    activeDay ??= week.isNotEmpty ? week.first : null;
    final minutes = week.fold<int>(0, (total, day) => total + day.durationMinutes);
    _dashboard = DashboardSummary(
      routineName: activeDay?.title ?? 'Sin rutina asignada',
      routineDate: activeDay?.dayLabel ?? '',
      durationMinutes: activeDay?.durationMinutes ?? 0,
      difficulty: activeDay == null ? '' : 'Personalizada',
      weeklyGoal: week.length,
      progressPercent: week.isEmpty ? 0 : completedDays / week.length,
      calories: 0,
      exerciseMinutes: minutes,
      activeStreak: completedDays,
    );
    _routines = week.map((day) => Routine(
      name: day.title,
      level: 'Personalizada',
      durationMinutes: day.durationMinutes,
      goal: _profile.goal,
      muscleGroup: day.muscleGroup,
      exercises: day.exercises,
    )).toList(growable: false);
    notifyListeners();
  }
}
