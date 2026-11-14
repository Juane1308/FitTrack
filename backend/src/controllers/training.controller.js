import { completeTrainingDay, getWeeklyTraining, recordWorkoutActivity } from '../services/training.service.js';
import {
  createUserRoutine,
  deleteUserRoutine,
  listSavedRoutineKeys,
  listUserRoutines,
  replaceSavedRoutineKeys,
} from '../services/user-routines.service.js';

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

export async function listUserRoutinesController(request, response, next) {
  try {
    return response.json({ data: await listUserRoutines(request.authUser.id) });
  } catch (error) {
    return next(error);
  }
}

export async function createUserRoutineController(request, response, next) {
  try {
    const routine = await createUserRoutine(request.authUser.id, request.body);
    return response.status(201).json({ data: routine });
  } catch (error) {
    return next(error);
  }
}

export async function deleteUserRoutineController(request, response, next) {
  try {
    await deleteUserRoutine(request.authUser.id, request.params.id);
    return response.status(204).end();
  } catch (error) {
    return next(error);
  }
}

export async function listSavedRoutinesController(request, response, next) {
  try {
    return response.json({ data: await listSavedRoutineKeys(request.authUser.id) });
  } catch (error) {
    return next(error);
  }
}

export async function replaceSavedRoutinesController(request, response, next) {
  try {
    const routineKeys = await replaceSavedRoutineKeys(request.authUser.id, request.body);
    return response.json({ data: routineKeys });
  } catch (error) {
    return next(error);
  }
}
