import { readFile } from 'node:fs/promises';

import { disconnectDatabase, getPrismaClient } from '../src/config/database.js';
import { listExercises } from '../src/services/exercise.service.js';
import { searchFoods } from '../src/services/food.service.js';
import { getRecipe, searchRecipes } from '../src/services/recipe.service.js';

const nutritionLimit = Number.parseInt(process.env.DATASET_LIMIT ?? '50', 10);
const exerciseLimit = Number.parseInt(process.env.EXERCISE_DATASET_LIMIT ?? '876', 10);
const nutritionDatasetPath = new URL('../data/nutrition/', import.meta.url);
const exerciseDatasetPath = new URL('../data/exercises/exercises.json', import.meta.url);
const prisma = getPrismaClient();

async function main() {
  const exercises = await loadExercises();
  const foods = await loadFoods();
  const recipes = await loadRecipes();

  const summary = {
    exercises: await saveExercises(exercises),
    foods: await saveFoods(foods),
    recipes: await saveRecipes(recipes),
  };

  console.log(JSON.stringify({ message: 'Catálogo guardado en PostgreSQL', ...summary }, null, 2));
}

async function loadExercises() {
  const localDataset = await readJsonFile(exerciseDatasetPath);
  if (Array.isArray(localDataset)) {
    const normalized = localDataset
      .map(normalizeDatasetExercise)
      .filter((exercise) => exercise.slug && exercise.name)
    return [...new Map(normalized.map((exercise) => [exercise.slug, exercise])).values()]
      .slice(0, exerciseLimit);
  }

  const groups = ['pecho', 'espalda', 'biceps', 'triceps', 'hombros', 'pierna', 'abdomen'];
  const results = await Promise.all(groups.map((group) => listExercises({ group, preferDatabase: false })));
  const unique = new Map();
  results.flat().forEach((exercise) => unique.set(exercise.slug, exercise));
  return [...unique.values()].slice(0, exerciseLimit);
}

async function loadFoods() {
  const localDataset = await readNutritionDataset('foods.json');
  if (localDataset) {
    return flattenCategories(localDataset.categories)
      .slice(0, nutritionLimit)
      .map((food) => ({
        name: food.nombre,
        category: food.categoria ?? food.__category ?? 'Alimentos',
        imageUrl: food.imagen_url ?? null,
        servingGrams: parseNumber(food.porcion),
        calories: parseNumber(food.calorias),
        fat: parseNumber(food.grasas_g),
        protein: parseNumber(food.proteina_g),
        carbohydrates: parseNumber(food.carbohidratos_g),
        fiber: parseNumber(food.fibra_g),
        mealTime: 'all',
        source: food.fuente ?? localDataset.source ?? 'dataset-nutrition-es',
        description: food.descripcion_saludable ?? '',
      }));
  }

  const result = await searchFoods({ search: '', meal: 'all', page: 1, pageSize: nutritionLimit, preferDatabase: false });
  return result.data ?? [];
}

async function loadRecipes() {
  const localDataset = await readNutritionDataset('recipes.json');
  if (localDataset) {
    return flattenCategories(localDataset.categories)
      .slice(0, Math.min(nutritionLimit, 200))
      .map((recipe) => ({
        id: String(recipe.id ?? ''),
        name: recipe.nombre,
        ingredients: recipe.ingredientes ?? [],
        instructions: recipe.instrucciones ?? recipe.pasos?.join('\n') ?? '',
        mealTime: recipe.__category ?? 'snack',
        imageUrl: recipe.imagen_url ?? null,
        sourceUrl: recipe.fuente_url ?? null,
        source: localDataset.source ?? 'dataset-nutrition-es',
      }));
  }

  const categories = ['breakfast', 'lunch', 'dinner', 'snack'];
  const results = await Promise.all(categories.map((meal) => searchRecipes({ meal, preferDatabase: false })));
  const candidates = [...new Map(
    results.flatMap((result) => result.data ?? []).map((recipe) => [recipe.id, recipe]),
  ).values()].slice(0, Math.min(nutritionLimit, 40));

  const detailed = [];
  for (const recipe of candidates) {
    try {
      detailed.push(await getRecipe(recipe.id, { preferDatabase: false }));
    } catch (error) {
      console.warn(`[seed] No se pudo cargar la receta ${recipe.id}: ${error.message}`);
      detailed.push(recipe);
    }
  }
  return detailed;
}

async function saveExercises(exercises) {
  const batchSize = 25;
  for (let index = 0; index < exercises.length; index += batchSize) {
    const batch = exercises.slice(index, index + batchSize);
    await Promise.all(batch.map(async (exercise) => {
      const existing = await prisma.exercise.findUnique({ where: { slug: exercise.slug } });
      const data = {
        name: exercise.name,
        technique: exercise.instructions?.join('\n') || exercise.description || 'Técnica no disponible.',
        description: exercise.description ?? null,
        muscleCategory: exercise.muscleCategory ?? null,
        level: difficultyValue(exercise.level),
        primaryMuscles: exercise.primaryMuscles ?? [],
        imageUrl: firstImage(exercise.images),
        videoUrl: null,
        equipment: exercise.equipment ?? null,
        source: exercise.source ?? 'free-exercise-db',
      };

      if (existing) {
        await prisma.exercise.update({ where: { id: existing.id }, data });
      } else {
        await prisma.exercise.create({ data: { slug: exercise.slug, ...data } });
      }
    }));
  }
  return exercises.length;
}

async function saveFoods(foods) {
  let saved = 0;
  for (const food of foods) {
    const existing = await prisma.food.findFirst({ where: { name: food.name } });
    const nutritionInfo = {
      barcode: food.barcode,
      imageUrl: food.imageUrl,
      servingGrams: food.servingGrams,
      calories: food.calories,
      fat: food.fat,
      protein: food.protein,
      carbohydrates: food.carbohydrates,
      fiber: food.fiber,
      mealTime: food.mealTime,
      source: food.source ?? 'open-food-facts-or-usda',
      description: food.description ?? '',
    };
    const data = { category: food.category || 'Alimentos', nutritionInfo };

    if (existing) {
      await prisma.food.update({ where: { id: existing.id }, data });
    } else {
      await prisma.food.create({ data: { name: food.name, ...data } });
    }
    saved += 1;
  }
  return saved;
}

async function saveRecipes(recipes) {
  let saved = 0;
  for (const recipe of recipes) {
    const existing = await prisma.recipe.findFirst({ where: { name: recipe.name } });
    const data = {
      ingredients: recipe.ingredients ?? [],
      instructions: recipe.instructions ?? '',
      mealTime: mealTimeValue(recipe.mealTime),
      imageUrl: recipe.imageUrl ?? null,
      sourceUrl: recipe.sourceUrl ?? null,
      source: String(recipe.source ?? 'TheMealDB').slice(0, 80),
    };

    if (existing) {
      await prisma.recipe.update({ where: { id: existing.id }, data });
    } else {
      await prisma.recipe.create({ data: { name: recipe.name, ...data } });
    }
    saved += 1;
  }
  return saved;
}

function firstImage(images) {
  if (typeof images === 'string') return images;
  if (Array.isArray(images)) return images.map(toExerciseImageUrl).find(Boolean) ?? null;
  if (!images || typeof images !== 'object') return null;
  return images.female ?? images.male ?? images.front ?? images.back ?? null;
}

function normalizeDatasetExercise(exercise) {
  const primarySource = Array.isArray(exercise.primaryMuscles) ? exercise.primaryMuscles : [];
  const secondarySource = Array.isArray(exercise.secondaryMuscles) ? exercise.secondaryMuscles : [];
  const originalMuscles = [...primarySource, ...secondarySource];
  const muscleCategory = datasetMuscleCategory(primarySource.length > 0 ? primarySource : secondarySource);
  const localizedMuscles = originalMuscles.map(localizeDatasetMuscle).filter(Boolean);

  return {
    slug: String(exercise.id ?? exercise.name ?? '').trim(),
    name: String(exercise.name ?? '').trim(),
    group: muscleCategory,
    level: String(exercise.level ?? 'intermediate').toLowerCase(),
    primaryMuscles: [...new Set(localizedMuscles)],
    instructions: Array.isArray(exercise.instructions) ? exercise.instructions : [],
    description: `Ejercicio de ${muscleCategory} para trabajar ${localizedMuscles.slice(0, 2).join(' y ') || 'la zona seleccionada'}.`,
    equipment: exercise.equipment
      ? { id: String(exercise.equipment).toLowerCase(), name: String(exercise.equipment) }
      : null,
    images: Array.isArray(exercise.images)
      ? exercise.images.map(toExerciseImageUrl).filter(Boolean)
      : [],
    muscleCategory,
    source: 'free-exercise-db',
  };
}

function difficultyValue(value) {
  const level = String(value ?? '').toLowerCase();
  if (level.includes('begin')) return 'BEGINNER';
  if (level.includes('expert') || level.includes('advanced')) return 'ADVANCED';
  return 'INTERMEDIATE';
}

function toExerciseImageUrl(image) {
  if (typeof image !== 'string' || !image.trim()) return null;
  if (/^https?:\/\//i.test(image)) return image;
  return `https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${image}`;
}

function datasetMuscleCategory(muscles) {
  const values = muscles.map((muscle) => String(muscle).toLowerCase());
  if (values.some((muscle) => muscle.includes('biceps'))) return 'biceps';
  if (values.some((muscle) => muscle.includes('triceps'))) return 'triceps';
  if (values.some((muscle) => /shoulder|deltoid/.test(muscle))) return 'hombros';
  if (values.some((muscle) => /chest|pectoral/.test(muscle))) return 'pecho';
  if (values.some((muscle) => /back|lat|trapezius|rhomboid|lower back/.test(muscle))) return 'espalda';
  if (values.some((muscle) => /abdom|oblique|serratus/.test(muscle))) return 'abdomen';
  if (values.some((muscle) => /quad|hamstring|glute|calf|leg|adductor|abductor/.test(muscle))) return 'pierna';
  if (values.some((muscle) => /forearm/.test(muscle))) return 'brazos';
  return 'general';
}

function localizeDatasetMuscle(muscle) {
  return {
    abdominals: 'Abdomen',
    abductors: 'Abductores',
    adductors: 'Aductores',
    biceps: 'Bíceps',
    calves: 'Pantorrillas',
    chest: 'Pecho',
    forearms: 'Antebrazos',
    glutes: 'Glúteos',
    hamstrings: 'Isquiotibiales',
    lats: 'Dorsales',
    'lower back': 'Zona lumbar',
    'middle back': 'Espalda media',
    neck: 'Cuello',
    quadriceps: 'Cuádriceps',
    shoulders: 'Hombros',
    traps: 'Trapecios',
    triceps: 'Tríceps',
  }[String(muscle).toLowerCase()] ?? String(muscle);
}

function mealTimeValue(value) {
  return {
    breakfast: 'BREAKFAST',
    desayunos: 'BREAKFAST',
    desayuno: 'BREAKFAST',
    lunch: 'LUNCH',
    almuerzos: 'LUNCH',
    almuerzo: 'LUNCH',
    dinner: 'DINNER',
    cenas: 'DINNER',
    cena: 'DINNER',
    comidas: 'DINNER',
    snack: 'SNACK',
    snacks: 'SNACK',
    merienda: 'SNACK',
  }[String(value ?? '').toLowerCase()] ?? 'SNACK';
}

async function readNutritionDataset(fileName) {
  return readJsonFile(new URL(fileName, nutritionDatasetPath));
}

async function readJsonFile(fileUrl) {
  try {
    return JSON.parse(await readFile(fileUrl, 'utf8'));
  } catch (_) {
    return null;
  }
}

function flattenCategories(categories) {
  return Object.entries(categories ?? {}).flatMap(([category, items]) =>
    (Array.isArray(items) ? items : []).map((item) => ({ ...item, __category: category })),
  );
}

function parseNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value !== 'string') return null;
  const parsed = Number.parseFloat(value.replace(',', '.'));
  return Number.isFinite(parsed) ? parsed : null;
}

main()
  .catch((error) => {
    console.error('[seed] No se pudo cargar el catálogo:', error);
    process.exitCode = 1;
  })
  .finally(() => disconnectDatabase());
