import { Router } from 'express';

import { getRecipeController, searchRecipesController } from '../controllers/recipe.controller.js';

export const recipeRouter = Router();

recipeRouter.get('/', searchRecipesController);
recipeRouter.get('/:id', getRecipeController);
