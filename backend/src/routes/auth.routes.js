import { Router } from 'express';

import {
  loginController,
  logoutController,
  passwordRecoveryController,
  registerController,
  resendVerificationController,
  verifyEmailController,
} from '../controllers/auth.controller.js';

export const authRouter = Router();

authRouter.post('/register', registerController);
authRouter.post('/login', loginController);
authRouter.post('/logout', logoutController);
authRouter.post('/password-recovery', passwordRecoveryController);
authRouter.post('/verify-email', verifyEmailController);
authRouter.post('/resend-verification', resendVerificationController);
