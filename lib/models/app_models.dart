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
  });

  final String name;
  final String technique;
  final int sets;
  final int repetitions;
}

class Food {
  const Food({required this.id, required this.name, required this.category});

  final String id;
  final String name;
  final String category;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.mealTime,
  });

  final String id;
  final String name;
  final List<String> ingredients;
  final String mealTime;
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
