import cors from 'cors';
import express from 'express';

import { errorMiddleware, notFoundMiddleware } from './middlewares/error.middleware.js';
import { authRouter } from './routes/auth.routes.js';
import { exerciseRouter } from './routes/exercise.routes.js';
import { foodRouter } from './routes/food.routes.js';
import { recipeRouter } from './routes/recipe.routes.js';
import { healthRouter } from './routes/health.routes.js';
import { profileRouter } from './routes/profile.routes.js';
import { chatRouter } from './routes/chat.routes.js';
import { trainingRouter } from './routes/training.routes.js';
import { recommendationRouter } from './routes/recommendation.routes.js';
import { progressRouter } from './routes/progress.routes.js';

export function createApp() {
  const app = express();

  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  app.get('/api', (_request, response) => {
    response.json({
      name: 'FITTRACK API',
      status: 'running',
      features: ['profile', 'chat', 'training', 'nutrition', 'recommendations'],
    });
  });
  app.use('/api/auth', authRouter);
  app.use('/api/exercises', exerciseRouter);
  app.use('/api/foods', foodRouter);
  app.use('/api/recipes', recipeRouter);
  app.use('/api/profile', profileRouter);
  app.use('/api/chat', chatRouter);
  app.use('/api/training', trainingRouter);
  app.use('/api/recommendations', recommendationRouter);
  app.use('/api/progress', progressRouter);
  app.use('/api/health', healthRouter);

  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  return app;
}
