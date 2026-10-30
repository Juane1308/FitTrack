import {
  askGemini,
  buildAssistantFallback,
  selectAssistantExercises,
} from '../services/gemini.service.js';
import { inferExerciseGroup, listExercises, requestedExerciseCount } from '../services/exercise.service.js';
import { getGeminiProfileContext, getUserProfile } from '../services/profile.service.js';

export async function chatController(request, response, next) {
  try {
    const { message, section, goal, exercises, foods } = request.body ?? {};
    if (typeof message !== 'string' || !message.trim()) {
      const error = new Error('Escribe una pregunta para el asistente.');
      error.statusCode = 400;
      throw error;
    }

    const profile = request.authUser?.id ? await getUserProfile(request.authUser.id) : null;
    const resolvedGoal = typeof goal === 'string' && goal ? goal : profile?.objective ?? '';
    const requestedGroup = inferExerciseGroup(message, section);
    const requestedCount = requestedExerciseCount(message);
    let exerciseCatalog = [];
    try {
      exerciseCatalog = await listExercises({
        group: requestedGroup,
        goal: resolvedGoal,
        trainingPlace: profile?.trainingPlace,
      });
    } catch (error) {
      console.error('[chat-exercise-catalog-error]', error.message);
    }

    const context = {
      message,
      section: typeof section === 'string' ? section : 'general',
      goal: resolvedGoal,
      exercises: Array.isArray(exercises) ? exercises : [],
      exerciseCatalog,
      foods: Array.isArray(foods) ? foods : [],
      condition: getGeminiProfileContext(profile),
      trainingPlace: profile?.trainingPlace ?? '',
      requestedGroup: requestedGroup ?? '',
      requestedCount,
    };

    let text;
    try {
      text = await askGemini(context);
    } catch (error) {
      console.warn(`[chat-gemini-fallback] ${error.message}`);
      text = buildAssistantFallback(context);
    }
    const recommendedExercises = selectAssistantExercises({
      message,
      responseText: text,
      exerciseCatalog,
      exercises,
      requestedCount,
    });
    return response.json({
      data: {
        message: text,
        exercises: recommendedExercises,
      },
    });
  } catch (error) {
    return next(error);
  }
}
