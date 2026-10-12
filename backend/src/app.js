import cors from 'cors';
import express from 'express';

import { errorMiddleware, notFoundMiddleware } from './middlewares/error.middleware.js';
import { authRouter } from './routes/auth.routes.js';
import { nutritionRouter } from './routes/nutrition.routes.js';

export function createApp() {
  const app = express();

  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  app.get('/api', (_request, response) => {
    response.json({
      name: 'FITTRACK API',
      status: 'running',
      features: ['register', 'login', 'email verification', 'password recovery', 'nutrition'],
    });
  });

  app.use('/api/auth', authRouter);
  app.use('/api/nutrition', nutritionRouter);
  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  return app;
}
