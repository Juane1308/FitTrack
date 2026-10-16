import { Router } from 'express';

import { requireAuth } from '../middlewares/auth.middleware.js';
import { getProfileController, updateProfileController } from '../controllers/profile.controller.js';

export const profileRouter = Router();

profileRouter.use(requireAuth);
profileRouter.get('/', getProfileController);
profileRouter.patch('/', updateProfileController);
