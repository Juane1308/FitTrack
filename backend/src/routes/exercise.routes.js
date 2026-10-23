import { Router } from 'express';

import {
  getExerciseController,
  listExercisesController,
} from '../controllers/exercise.controller.js';

export const exerciseRouter = Router();

exerciseRouter.get('/', listExercisesController);
exerciseRouter.get('/:slug', getExerciseController);
