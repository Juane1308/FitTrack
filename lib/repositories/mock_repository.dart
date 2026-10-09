import '../models/app_models.dart';

class MockRepository {
  AppUser get currentUser => const AppUser(
    name: 'Samuel',
    email: 'samuel@fittrack.local',
    goal: 'Ganar fuerza',
  );

  DashboardSummary get dashboard => const DashboardSummary(
    routineName: 'Fuerza de tren superior',
    routineDate: 'Hoy, 26 de septiembre',
    durationMinutes: 45,
    difficulty: 'Intermedia',
    weeklyGoal: 4,
    progressPercent: 0.75,
    calories: 320,
    exerciseMinutes: 135,
    activeStreak: 6,
  );

  List<Routine> get routines => const [
    Routine(
      name: 'Fuerza de tren superior',
      level: 'Intermedio',
      durationMinutes: 45,
      goal: 'Ganar fuerza',
      muscleGroup: 'Tren superior',
      exercises: [
        Exercise(
          name: 'Press de pecho',
          technique: 'Mantén la espalda apoyada y controla el descenso.',
          sets: 4,
          repetitions: 10,
        ),
        Exercise(
          name: 'Remo con mancuerna',
          technique: 'Conserva la espalda recta y lleva el codo hacia atrás.',
          sets: 3,
          repetitions: 12,
        ),
      ],
    ),
  ];

  List<Food> get foods => const [
    Food(id: 'food-1', name: 'Avena', category: 'Cereales'),
    Food(id: 'food-2', name: 'Huevo', category: 'Proteínas'),
    Food(id: 'food-3', name: 'Banano', category: 'Frutas'),
  ];

  List<Recipe> get recipes => const [
    Recipe(
      id: 'recipe-1',
      name: 'Avena con banano',
      ingredients: ['Avena', 'Leche', 'Banano'],
      mealTime: 'Desayuno',
    ),
  ];

  List<ProgressEntry> get progress => const [
    ProgressEntry(date: '2026-09-01', weight: 72.4, height: 1.74),
    ProgressEntry(date: '2026-09-15', weight: 71.8, height: 1.74),
    ProgressEntry(date: '2026-09-26', weight: 71.2, height: 1.74),
  ];
}
