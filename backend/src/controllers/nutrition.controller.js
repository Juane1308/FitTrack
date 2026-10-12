import {
  getFoodCategories,
  getFoods,
  getRecipeCategories,
  getRecipeDetail,
  getRecipes,
} from '../services/nutrition.service.js';

export async function recipeCategoriesController(_request, response) {
  response.json({ categories: getRecipeCategories() });
}

export async function recipesController(request, response) {
  response.json(await getRecipes(request.query.meal, request.query.offset));
}

export async function recipeDetailController(request, response) {
  response.json({ recipe: await getRecipeDetail(request.params.id) });
}

export async function foodCategoriesController(_request, response) {
  response.json({ categories: getFoodCategories() });
}

export async function foodsController(request, response) {
  response.json({ foods: await getFoods(request.query.category) });
}

