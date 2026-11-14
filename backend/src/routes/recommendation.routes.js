import { Router } from 'express';

import { requireAuth } from '../middlewares/auth.middleware.js';
import { recommendationController } from '../controllers/recommendation.controller.js';

export const recommendationRouter = Router();

recommendationRouter.use(requireAuth);
recommendationRouter.get('/', recommendationController);
