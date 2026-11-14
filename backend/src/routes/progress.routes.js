import { Router } from 'express';

import { requireAuth } from '../middlewares/auth.middleware.js';
import { createProgressEntryController, createProgressPhotoController, progressController } from '../controllers/progress.controller.js';

export const progressRouter = Router();

progressRouter.use(requireAuth);
progressRouter.get('/', progressController);
progressRouter.post('/entries', createProgressEntryController);
progressRouter.post('/photos', createProgressPhotoController);
