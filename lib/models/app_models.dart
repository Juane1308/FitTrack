import '../core/constants/app_constants.dart';

class AppUser {
  const AppUser({required this.name, required this.email, required this.goal});

  final String name;
  final String email;
  final String goal;

  AppUser copyWith({String? name, String? email, String? goal}) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      goal: goal ?? this.goal,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.goal,
    required this.birthDate,
    required this.weight,
    required this.height,
    required this.sport,
    required this.trainingPlace,
    required this.injuries,
    required this.pain,
    required this.surgeries,
    required this.diseases,
    required this.allergies,
    this.trainingDays = 4,
    this.notificationsEnabled = true,
    this.privateProfile = true,
  });

  final String goal;
  final DateTime? birthDate;
  final double? weight;
  final double? height;
  final String sport;
  final String trainingPlace;
  final String injuries;
  final String pain;
  final String surgeries;
  final String diseases;
  final String allergies;
  final int trainingDays;
  final bool notificationsEnabled;
  final bool privateProfile;

  UserProfile copyWith({
    String? goal,
    DateTime? birthDate,
    double? weight,
    double? height,
    String? sport,
    String? trainingPlace,
    String? injuries,
    String? pain,
    String? surgeries,
    String? diseases,
    String? allergies,
    int? trainingDays,
    bool? notificationsEnabled,
    bool? privateProfile,
  }) {
    return UserProfile(
      goal: goal ?? this.goal,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      sport: sport ?? this.sport,
      trainingPlace: trainingPlace ?? this.trainingPlace,
      injuries: injuries ?? this.injuries,
      pain: pain ?? this.pain,
      surgeries: surgeries ?? this.surgeries,
      diseases: diseases ?? this.diseases,
      allergies: allergies ?? this.allergies,
      trainingDays: trainingDays ?? this.trainingDays,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      privateProfile: privateProfile ?? this.privateProfile,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.routineName,
    required this.routineDate,
    required this.durationMinutes,
    required this.difficulty,
    required this.weeklyGoal,
    required this.progressPercent,
    required this.calories,
    required this.exerciseMinutes,
    required this.activeStreak,
  });

  final String routineName;
  final String routineDate;
  final int durationMinutes;
  final String difficulty;
  final int weeklyGoal;
  final double progressPercent;
  final double calories;
  final int exerciseMinutes;
  final int activeStreak;
}

class WorkoutDay {
  const WorkoutDay({
    required this.date,
    required this.dayLabel,
    required this.muscleGroup,
    required this.title,
    required this.durationMinutes,
    required this.completed,
    required this.exercises,
  });

  final String date;
  final String dayLabel;
  final String muscleGroup;
  final String title;
  final int durationMinutes;
  final bool completed;
  final List<Exercise> exercises;

  WorkoutDay copyWith({bool? completed}) => WorkoutDay(
    date: date,
    dayLabel: dayLabel,
    muscleGroup: muscleGroup,
    title: title,
    durationMinutes: durationMinutes,
    completed: completed ?? this.completed,
    exercises: exercises,
  );
}

class Routine {
  const Routine({
    required this.name,
    required this.level,
    required this.durationMinutes,
    required this.goal,
    required this.muscleGroup,
    required this.exercises,
  });

  final String name;
  final String level;
  final int durationMinutes;
  final String goal;
  final String muscleGroup;
  final List<Exercise> exercises;
}

class Exercise {
  const Exercise({
    required this.name,
    required this.technique,
    required this.sets,
    required this.repetitions,
    this.slug = '',
    this.group = '',
    this.primaryMuscle = '',
    this.muscleCategory = 'general',
    this.recommendedRepetitions = '8-12',
    this.recommendationFocus = 'técnica y movimiento seguro',
    this.imageUrl,
    this.instructions = const [],
    this.description = '',
  });

  final String name;
  final String technique;
  final int sets;
  final int repetitions;
  final String slug;
  final String group;
  final String primaryMuscle;
  final String muscleCategory;
  final String recommendedRepetitions;
  final String recommendationFocus;
  final String? imageUrl;
  final List<String> instructions;
  final String description;
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    this.barcode,
    this.servingGrams,
    this.calories,
    this.fat,
    this.protein,
    this.carbohydrates,
    this.fiber,
    this.mealTime = 'all',
  });

  final String id;
  final String name;
  final String category;
  final String? imageUrl;
  final String? barcode;
  final double? servingGrams;
  final double? calories;
  final double? fat;
  final double? protein;
  final double? carbohydrates;
  final double? fiber;
  final String mealTime;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.mealTime,
    this.imageUrl,
    this.instructions,
    this.sourceUrl,
  });

  final String id;
  final String name;
  final List<String> ingredients;
  final String mealTime;
  final String? imageUrl;
  final String? instructions;
  final String? sourceUrl;
}

class PersonalizedRecommendation {
  const PersonalizedRecommendation({
    required this.generatedBy,
    required this.trainingTitle,
    required this.trainingSummary,
    required this.trainingGroups,
    required this.safetyNotes,
    required this.nutritionMethod,
    required this.nutritionSummary,
    required this.meals,
    required this.focusFoods,
  });

  final String generatedBy;
  final String trainingTitle;
  final String trainingSummary;
  final List<String> trainingGroups;
  final List<String> safetyNotes;
  final String nutritionMethod;
  final String nutritionSummary;
  final List<String> meals;
  final List<String> focusFoods;
}

class ProgressEntry {
  const ProgressEntry({
    required this.date,
    required this.weight,
    required this.height,
  });

  final String date;
  final double weight;
  final double height;
}

class ChatContext {
  const ChatContext({required this.section, this.selectedItem});

  final AppSection section;
  final String? selectedItem;
}
