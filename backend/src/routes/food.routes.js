import { Router } from 'express';

import { getFoodController, searchFoodsController } from '../controllers/food.controller.js';

export const foodRouter = Router();

foodRouter.get('/', searchFoodsController);
foodRouter.get('/:barcode', getFoodController);
