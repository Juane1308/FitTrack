import { getExercise, listExercises } from '../services/exercise.service.js';

export async function listExercisesController(request, response, next) {
  try {
    const exercises = await listExercises({
      group: request.query.group,
      goal: request.query.goal,
    });
    return response.json({ data: exercises });
  } catch (error) {
    return next(error);
  }
}

export async function getExerciseController(request, response, next) {
  try {
    const exercise = await getExercise(request.params.slug);
    return response.json({ data: exercise });
  } catch (error) {
    return next(error);
  }
}
