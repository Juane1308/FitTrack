import { completeTrainingDay, getWeeklyTraining, recordWorkoutActivity } from '../services/training.service.js';

export async function weeklyTrainingController(request, response, next) {
  try {
    return response.json({ data: await getWeeklyTraining(request.authUser.id) });
  } catch (error) {
    return next(error);
  }
}

export async function completeTrainingDayController(request, response, next) {
  try {
    const completed = request.body?.completed !== false;
    return response.json({ data: await completeTrainingDay(request.authUser.id, request.params.date, completed) });
  } catch (error) {
    return next(error);
  }
}

export async function recordWorkoutActivityController(request, response, next) {
  try {
    const activity = await recordWorkoutActivity(request.authUser.id, request.body);
    return response.status(201).json({ data: activity });
  } catch (error) {
    return next(error);
  }
}
