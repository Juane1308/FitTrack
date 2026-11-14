import { getRecipe, searchRecipes } from '../services/recipe.service.js';

export async function searchRecipesController(request, response, next) {
  try {
    return response.json(await searchRecipes({
      meal: request.query.meal,
      search: request.query.search,
    }));
  } catch (error) {
    return next(error);
  }
}

export async function getRecipeController(request, response, next) {
  try {
    return response.json({ data: await getRecipe(request.params.id) });
  } catch (error) {
    return next(error);
  }
}
