import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/mock_repository.dart';
import '../repositories/profile_repository.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider({
    MockRepository? repository,
    ProfileRepository? profileRepository,
  })  : _repository = repository ?? MockRepository(),
        _profileRepository = profileRepository ?? ProfileRepository();

  final MockRepository _repository;
  final ProfileRepository _profileRepository;

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

  AppUser get currentUser => _repository.currentUser;
  UserProfile get profile => _profile;
  DashboardSummary get dashboard => _repository.dashboard;
  List<Routine> get routines => _repository.routines;
  List<Food> get foods => _repository.foods;
  List<Recipe> get recipes => _repository.recipes;
  List<ProgressEntry> get progress => _repository.progress;

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
}
