import { Router } from 'express';

import { requireAuth } from '../middlewares/auth.middleware.js';
import {
  completeTrainingDayController,
  createUserRoutineController,
  deleteUserRoutineController,
  listSavedRoutinesController,
  listUserRoutinesController,
  recordWorkoutActivityController,
  replaceSavedRoutinesController,
  weeklyTrainingController,
} from '../controllers/training.controller.js';

export const trainingRouter = Router();

trainingRouter.use(requireAuth);
trainingRouter.get('/routines', listUserRoutinesController);
trainingRouter.post('/routines', createUserRoutineController);
trainingRouter.delete('/routines/:id', deleteUserRoutineController);
trainingRouter.get('/favorites', listSavedRoutinesController);
trainingRouter.put('/favorites', replaceSavedRoutinesController);
trainingRouter.get('/week', weeklyTrainingController);
trainingRouter.patch('/week/:date', completeTrainingDayController);
trainingRouter.post('/activities', recordWorkoutActivityController);
