import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const directory = path.join(path.dirname(fileURLToPath(import.meta.url)), '../../data/nutrition');
const recipesDataset = JSON.parse(fs.readFileSync(path.join(directory, 'recipes.json'), 'utf8'));
const foodsDataset = JSON.parse(fs.readFileSync(path.join(directory, 'foods.json'), 'utf8'));

const recipeCategories = [
  { id: 'desayunos', label: 'Desayunos', image: 'assets/images/nutrition_breakfast.jpg' },
  { id: 'almuerzos', label: 'Almuerzos', image: 'assets/images/nutrition_lunch.jpg' },
  { id: 'comidas', label: 'Cenas y comidas', image: 'assets/images/nutrition_dinner.jpg' },
  { id: 'snacks', label: 'Snacks', image: 'assets/images/nutrition_snack.jpg' },
  { id: 'bebidas', label: 'Bebidas', image: 'assets/images/nutrition_breakfast.jpg' },
  { id: 'dulces', label: 'Dulces saludables', image: 'assets/images/nutrition_sweets.jpg' },
];
const foodCategories = [
  { id: 'carbohidratos', label: 'Carbohidratos', description: 'Energía para el cerebro y el movimiento.', icon: 'energy', image: 'assets/images/nutrition/foods/food-000.jpg' },
  { id: 'proteinas', label: 'Proteínas', description: 'Aminoácidos para formar y reparar tejidos.', icon: 'protein', image: 'assets/images/nutrition/foods/food-008.jpg' },
  { id: 'grasas', label: 'Grasas saludables', description: 'Aportan energía y ayudan a absorber vitaminas.', icon: 'fat', image: 'assets/images/nutrition/foods/food-014.jpg' },
  { id: 'vitaminas', label: 'Vitaminas', description: 'Micronutrientes que apoyan funciones esenciales del organismo.', icon: 'vitamins', image: 'assets/images/nutrition/foods/food-022.jpg' },
  { id: 'minerales', label: 'Minerales', description: 'Nutrientes que contribuyen a funciones como huesos y músculos.', icon: 'minerals', image: 'assets/images/nutrition/foods/food-030.jpg' },
  { id: 'frutas_verduras', label: 'Frutas y verduras', description: 'Fuentes variadas de fibra, vitaminas y minerales.', icon: 'produce', image: 'assets/images/nutrition/foods/food-034.jpg' },
  { id: 'legumbres', label: 'Legumbres', description: 'Aportan fibra y proteínas vegetales.', icon: 'legumes', image: 'assets/images/nutrition/foods/food-040.jpg' },
  { id: 'lacteos', label: 'Lácteos y alternativas', description: 'Opciones que aportan proteínas y otros nutrientes.', icon: 'dairy', image: 'assets/images/nutrition/foods/food-041.jpg' },
];

export function getRecipeCategories() {
  return recipeCategories;
}

export function getFoodCategories() {
  return foodCategories;
}

export async function getRecipes(mealId, offset = 0) {
  const category = String(mealId ?? '');
  const recipes = recipesDataset.categories[category];
  if (!recipes) throw httpError(400, 'Selecciona una categoría de recetas válida.');
  const safeOffset = Number.isInteger(Number(offset)) ? Math.max(0, Number(offset)) : 0;
  const pageSize = 24;
  const page = recipes.slice(safeOffset, safeOffset + pageSize);
  return {
    recipes: page,
    offset: safeOffset,
    totalResults: recipes.length,
    hasMore: safeOffset + page.length < recipes.length,
  };
}

export async function getRecipeDetail(id) {
  const recipeId = Number(id);
  if (!Number.isInteger(recipeId) || recipeId <= 0) throw httpError(400, 'La receta indicada no es válida.');
  const recipe = Object.values(recipesDataset.categories).flat().find((item) => item.id === recipeId);
  if (!recipe) throw httpError(404, 'No se encontró el detalle de la receta.');
  return recipe;
}

export async function getFoods(categoryId) {
  const foods = foodsDataset.categories[String(categoryId ?? '')];
  if (!foods) throw httpError(400, 'Selecciona una categoría de alimentos válida.');
  return foods;
}

function httpError(statusCode, message) {
  return Object.assign(new Error(message), { statusCode });
}
