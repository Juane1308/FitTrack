import { getPrismaClient } from '../config/database.js';

export async function listStoredExercises({ group, pageSize = 200 } = {}) {
  try {
    const prisma = getPrismaClient();
    const normalized = String(group ?? '').trim().toLowerCase();
    const groups = normalized === 'brazos' ? ['biceps', 'triceps'] : normalized ? [normalized] : [];
    const rows = await prisma.exercise.findMany({
      where: groups.length > 0
        ? { OR: groups.map((value) => ({ muscleCategory: { contains: value, mode: 'insensitive' } })) }
        : undefined,
      orderBy: { name: 'asc' },
      take: pageSize,
    });

    return rows.map((row) => ({
      slug: row.slug ?? row.id,
      name: row.name,
      group: row.muscleCategory ?? '',
      primaryMuscles: asArray(row.primaryMuscles),
      instructions: row.technique ? row.technique.split('\n').filter(Boolean) : [],
      description: row.description ?? '',
      equipment: row.equipment ?? null,
      images: row.imageUrl ? { female: row.imageUrl, male: row.imageUrl } : {},
      muscleMap: null,
      muscleCategory: row.muscleCategory ?? 'general',
      source: row.source ?? 'database',
    }));
  } catch (error) {
    console.warn(`[catalog-db] ejercicios no disponibles: ${error.message}`);
    return [];
  }
}

export async function getStoredExercise(slug) {
  try {
    const lookup = [{ slug }];
    if (isUuid(slug)) lookup.push({ id: slug });
    const row = await getPrismaClient().exercise.findFirst({
      where: { OR: lookup },
    });
    if (!row) return null;
    return {
      slug: row.slug ?? row.id,
      name: row.name,
      group: row.muscleCategory ?? '',
      primaryMuscles: asArray(row.primaryMuscles),
      instructions: row.technique ? row.technique.split('\n').filter(Boolean) : [],
      description: row.description ?? '',
      equipment: row.equipment ?? null,
      images: row.imageUrl ? { female: row.imageUrl, male: row.imageUrl } : {},
      muscleMap: null,
      muscleCategory: row.muscleCategory ?? 'general',
      source: row.source ?? 'database',
    };
  } catch (error) {
    console.warn(`[catalog-db] ejercicio no disponible: ${error.message}`);
    return null;
  }
}

export async function searchStoredFoods({ search, meal = 'all', page = 1, pageSize = 20 } = {}) {
  try {
    const term = String(search ?? '').trim();
    const rows = await getPrismaClient().food.findMany({
      where: term ? { name: { contains: term, mode: 'insensitive' } } : undefined,
      orderBy: { name: 'asc' },
      skip: (page - 1) * pageSize,
      take: pageSize,
    });
    const data = rows
      .map((row) => foodFromRow(row))
      .filter((food) => meal === 'all' || food.mealTime === meal);
    return { count: data.length, page, data };
  } catch (error) {
    console.warn(`[catalog-db] alimentos no disponibles: ${error.message}`);
    return { count: 0, page, data: [] };
  }
}

export async function searchStoredRecipes({ meal = 'all', search = '' } = {}) {
  try {
    const term = String(search ?? '').trim();
    const rows = await getPrismaClient().recipe.findMany({
      where: term ? { name: { contains: term, mode: 'insensitive' } } : undefined,
      orderBy: { name: 'asc' },
    });
    const data = rows
      .map(recipeFromRow)
      .filter((recipe) => meal === 'all' || recipe.mealTime === meal);
    return { count: data.length, data };
  } catch (error) {
    console.warn(`[catalog-db] recetas no disponibles: ${error.message}`);
    return { count: 0, data: [] };
  }
}

export async function getStoredRecipe(id) {
  try {
    const row = await getPrismaClient().recipe.findUnique({ where: { id } });
    return row ? recipeFromRow(row) : null;
  } catch (error) {
    console.warn(`[catalog-db] receta no disponible: ${error.message}`);
    return null;
  }
}

function foodFromRow(row) {
  const info = row.nutritionInfo && typeof row.nutritionInfo === 'object' ? row.nutritionInfo : {};
  return {
    id: row.id,
    barcode: info.barcode ?? null,
    name: row.name,
    category: row.category,
    imageUrl: info.imageUrl ?? null,
    servingGrams: info.servingGrams ?? null,
    calories: info.calories ?? null,
    fat: info.fat ?? null,
    protein: info.protein ?? null,
    carbohydrates: info.carbohydrates ?? null,
    fiber: info.fiber ?? null,
    mealTime: info.mealTime ?? 'all',
  };
}

function recipeFromRow(row) {
  return {
    id: row.id,
    name: row.name,
    imageUrl: row.imageUrl ?? null,
    mealTime: String(row.mealTime).toLowerCase(),
    ingredients: asArray(row.ingredients),
    instructions: row.instructions ?? '',
    sourceUrl: row.sourceUrl ?? null,
    source: row.source ?? 'database',
  };
}

function asArray(value) {
  return Array.isArray(value) ? value : [];
}

function isUuid(value) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(String(value ?? ''));
}
