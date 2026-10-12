import { Router } from 'express';

import {
  foodCategoriesController,
  foodsController,
  recipeCategoriesController,
  recipeDetailController,
  recipesController,
} from '../controllers/nutrition.controller.js';

export const nutritionRouter = Router();

nutritionRouter.get('/recipe-categories', recipeCategoriesController);
nutritionRouter.get('/recipes', recipesController);
nutritionRouter.get('/recipes/:id', recipeDetailController);
nutritionRouter.get('/food-categories', foodCategoriesController);
nutritionRouter.get('/foods', foodsController);

