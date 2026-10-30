import '../models/app_models.dart';

/// Guía breve en español para que las instrucciones del dataset en inglés no
/// aparezcan sin traducir en las pantallas del entrenamiento.
List<String> exerciseInstructionsInSpanish(Exercise exercise) {
  final muscle = exercise.primaryMuscle.isNotEmpty
      ? exercise.primaryMuscle.toLowerCase()
      : exercise.muscleCategory.toLowerCase();
  return [
    'Colócate en una posición estable y activa los músculos de $muscle. Mantén la espalda alineada antes de iniciar.',
    'Realiza el movimiento con control, respira de forma continua y utiliza un recorrido cómodo. Evita los rebotes.',
    'Regresa despacio a la posición inicial y conserva el control durante cada repetición. Si sientes dolor, detén el ejercicio.',
  ];
}
