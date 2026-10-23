import { Router } from 'express';

import { requireAuth } from '../middlewares/auth.middleware.js';
import { completeTrainingDayController, weeklyTrainingController } from '../controllers/training.controller.js';

export const trainingRouter = Router();

trainingRouter.use(requireAuth);
trainingRouter.get('/week', weeklyTrainingController);
trainingRouter.patch('/week/:date', completeTrainingDayController);
