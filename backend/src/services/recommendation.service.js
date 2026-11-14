import { getPrismaClient } from '../config/database.js';
import { searchFoods } from './food.service.js';
import { suggestNutritionStrategy, suggestTrainingGroupOrder } from './gemini.service.js';
import { getGeminiProfileContext } from './profile.service.js';

const AVAILABLE_GROUPS = ['pecho', 'espalda', 'hombros', 'brazos', 'pierna', 'abdomen', 'cuerpo completo'];

export async function getPersonalizedRecommendation(userId, { refresh = false } = {}) {
  const prisma = getPrismaClient();
  const profile = await prisma.userProfile.findUnique({ where: { userId } });
  if (!profile?.objective || profile.weight == null || profile.height == null) {
    const error = new Error('Completa tu perfil antes de generar recomendaciones.');
    error.statusCode = 400;
    throw error;
  }

  const preferences = asObject(profile.preferences);
  if (!refresh && preferences.aiRecommendation) return preferences.aiRecommendation;

  const safeGroups = groupsAllowedByProfile(AVAILABLE_GROUPS, profile);
  const condition = getGeminiProfileContext(profile);
  const [orderedGroups, foodResult] = await Promise.all([
    suggestTrainingGroupOrder({ goal: profile.objective, availableGroups: safeGroups, condition }),
    searchFoods({ pageSize: 16 }),
  ]);
  const groups = orderedGroups ?? safeGroups;
  const nutrition = await suggestNutritionStrategy({ goal: profile.objective, foods: foodResult.data, condition });
  const recommendation = {
    generatedBy: nutrition ? 'gemini' : 'fittrack-safe-fallback',
    training: {
      title: trainingTitle(profile.objective),
      summary: trainingSummary(profile.objective, groups),
      groups,
      safetyNotes: safetyNotes(profile),
    },
    nutrition: nutrition ?? fallbackNutrition(profile.objective),
    createdAt: new Date().toISOString(),
  };

  await prisma.userProfile.update({
    where: { userId },
    data: { preferences: { ...preferences, aiRecommendation: recommendation } },
  });
  return recommendation;
}

function groupsAllowedByProfile(groups, profile) {
  const condition = [profile.injuries, profile.surgeries, profile.pain, profile.diseases]
    .filter(Boolean).join(' ').toLowerCase();
  const blocked = new Set();
  if (/rodilla|knee|tobillo|ankle|cadera|hip|fémur|femur/.test(condition)) blocked.add('pierna');
  if (/hombro|shoulder|manguito|clavícula|clavicula/.test(condition)) blocked.add('hombros');
  if (/espalda|lumbar|columna|back|hernia/.test(condition)) blocked.add('espalda');
  if (/codo|elbow|muñeca|muneca|wrist/.test(condition)) blocked.add('brazos');
  return groups.filter((group) => !blocked.has(group) || group === 'cuerpo completo');
}

function safetyNotes(profile) {
  const notes = [];
  if ([profile.injuries, profile.surgeries, profile.pain, profile.diseases].some((value) => value?.trim())) {
    notes.push('Tu rutina evita grupos asociados a los antecedentes registrados; valida los ejercicios con un profesional de salud.');
  }
  if (profile.allergies?.trim()) notes.push('Revisa ingredientes y etiquetas antes de consumir un alimento.');
  if (notes.length === 0) notes.push('Prioriza técnica, progresión gradual y detente si aparece dolor.');
  return notes;
}

function trainingTitle(goal) {
  return {
    STRENGTH: 'Rutina recomendada para fuerza',
    MUSCLE_GAIN: 'Rutina recomendada para masa muscular',
    WEIGHT_LOSS: 'Rutina recomendada para pérdida de grasa',
    GENERAL_FITNESS: 'Rutina recomendada para mantenerte activo',
  }[goal] ?? 'Rutina recomendada';
}

function trainingSummary(goal, groups) {
  const focus = groups.slice(0, 4).join(', ');
  return `La selección prioriza ${focus} de acuerdo con tu meta de ${String(goal).toLowerCase().replaceAll('_', ' ')}.`;
}

function fallbackNutrition(goal) {
  const method = goal === 'WEIGHT_LOSS' ? 'Plato equilibrado con déficit moderado' : 'Plato equilibrado y proteína suficiente';
  return {
    method,
    summary: 'Distribuye alimentos variados y ajusta porciones según tu progreso; usa los valores reales del catálogo para decidir.',
    meals: ['Desayuno con proteína y fruta', 'Almuerzo con proteína, vegetales y carbohidrato', 'Cena ligera y equilibrada'],
    focusFoods: [],
  };
}

function asObject(value) {
  return value && typeof value === 'object' && !Array.isArray(value) ? value : {};
}
