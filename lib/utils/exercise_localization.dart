import '../data/exercise_techniques_es.dart';
import '../models/app_models.dart';

/// Devuelve pasos específicos en español cuando existe una traducción validada
/// para el ejercicio del catálogo actual. No presenta instrucciones genéricas
/// como si describieran la técnica particular de un movimiento.
List<String> exerciseInstructionsInSpanish(Exercise exercise) {
  final instructions = exerciseTechniquesEs[exercise.slug];
  if (instructions != null && instructions.isNotEmpty) {
    return instructions;
  }

  return [
    'Todavía no hay una guía técnica específica en español para ${exercise.name}.',
    'Antes de realizarlo, revisa una demostración confiable o consulta a un entrenador para confirmar la postura y el recorrido adecuados.',
    'Detén el ejercicio si sientes dolor.',
  ];
}
