import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/mock_repository.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider({MockRepository? repository})
    : _repository = repository ?? MockRepository();

  final MockRepository _repository;

  AppUser get currentUser => _repository.currentUser;
  DashboardSummary get dashboard => _repository.dashboard;
  List<Routine> get routines => _repository.routines;
  List<Food> get foods => _repository.foods;
  List<Recipe> get recipes => _repository.recipes;
  List<ProgressEntry> get progress => _repository.progress;
}
