import { translateRecipeContent, translateRecipeNames } from './gemini.service.js';
import { getStoredRecipe, searchStoredRecipes } from './catalog-db.service.js';

const MEAL_DB_BASE = 'https://www.themealdb.com/api/json/v1/1';
const USER_AGENT = 'FITTRACK/1.0 (academic project)';

// TheMealDB is a real, public recipe catalogue. These source categories are
// translated to the meal moments shown by FitTrack in the client.
const SOURCE_CATEGORIES = {
  snack: 'Starter',
  breakfast: 'Breakfast',
  lunch: 'Chicken',
  dinner: 'Seafood',
};

export async function searchRecipes({ meal = 'all', search = '', preferDatabase = true } = {}) {
  if (preferDatabase) {
    const stored = await searchStoredRecipes({ meal, search });
    if (stored.data.length > 0) return stored;
  }

  const normalizedMeal = SOURCE_CATEGORIES[meal] ? meal : 'all';
  const query = search.trim();

  if (query) {
    const payload = await requestJson(`/search.php?s=${encodeURIComponent(query)}`);
    const data = (payload.meals ?? []).map((recipe) => normalizeRecipe(recipe, normalizedMeal));
    return {
      count: data.length,
      data: await translateRecipeNames(data),
    };
  }

  const meals = normalizedMeal === 'all' ? Object.keys(SOURCE_CATEGORIES) : [normalizedMeal];
  const responses = await Promise.all(
    meals.map(async (mealKey) => {
      const category = SOURCE_CATEGORIES[mealKey];
      const payload = await requestJson(`/filter.php?c=${encodeURIComponent(category)}`);
      return (payload.meals ?? []).map((recipe) => normalizeRecipe(recipe, mealKey));
    }),
  );
  const unique = new Map();
  responses.flat().forEach((recipe) => unique.set(recipe.id, recipe));
  const data = [...unique.values()];
  return { count: unique.size, data: await translateRecipeNames(data) };
}

export async function getRecipe(id, { preferDatabase = true } = {}) {
  if (preferDatabase) {
    const stored = await getStoredRecipe(id);
    if (stored) return stored;
  }

  const payload = await requestJson(`/lookup.php?i=${encodeURIComponent(id)}`);
  const recipe = payload.meals?.[0];
  if (!recipe) {
    const error = new Error('La receta no está disponible.');
    error.statusCode = 404;
    throw error;
  }
  return translateRecipeContent(normalizeRecipe(recipe, 'all', true));
}

function normalizeRecipe(recipe, mealTime, includeDetails = false) {
  const ingredients = [];
  for (let index = 1; index <= 20; index += 1) {
    const ingredient = recipe[`strIngredient${index}`]?.trim();
    const measure = recipe[`strMeasure${index}`]?.trim();
    if (ingredient) ingredients.push([measure, ingredient].filter(Boolean).join(' '));
  }

  return {
    id: recipe.idMeal ?? '',
    name: recipe.strMeal ?? 'Receta',
    imageUrl: recipe.strMealThumb ?? null,
    mealTime,
    ingredients,
    instructions: includeDetails ? recipe.strInstructions ?? '' : null,
    sourceUrl: includeDetails ? recipe.strSource ?? recipe.strYoutube ?? null : null,
    source: 'TheMealDB',
  };
}

async function requestJson(path) {
  const response = await fetch(`${MEAL_DB_BASE}${path}`, {
    headers: { 'User-Agent': USER_AGENT },
    signal: AbortSignal.timeout(12000),
  });
  if (!response.ok) {
    const error = new Error('No se pudo consultar el catálogo de recetas.');
    error.statusCode = 502;
    throw error;
  }
  return response.json();
}
