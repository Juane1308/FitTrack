import { getPrismaClient } from '../config/database.js';
import { AuthError } from './auth.service.js';
import { listExercises } from './exercise.service.js';
import { suggestTrainingGroupOrder } from './gemini.service.js';
import { getGeminiProfileContext } from './profile.service.js';

const GROUP_LABELS = {
  pecho: 'Pecho',
  espalda: 'Espalda',
  brazos: 'Brazos',
  pierna: 'Pierna',
  hombros: 'Hombros',
  abdomen: 'Abdomen',
};

const GROUPS_BY_DAYS = {
  1: ['cuerpo completo'],
  2: ['pecho', 'pierna'],
  3: ['pecho', 'espalda', 'pierna'],
  4: ['pecho', 'espalda', 'brazos', 'pierna'],
  5: ['pecho', 'espalda', 'hombros', 'pierna', 'brazos'],
  6: ['pecho', 'espalda', 'hombros', 'brazos', 'pierna', 'abdomen'],
  7: ['pecho', 'espalda', 'hombros', 'brazos', 'pierna', 'abdomen', 'cuerpo completo'],
};

export async function getWeeklyTraining(userId) {
  const prisma = getPrismaClient();
  const profile = await prisma.userProfile.findUnique({ where: { userId } });
  if (!profile?.objective || profile.weight == null || profile.height == null) {
    throw new AuthError(400, 'Completa tu perfil antes de generar tu rutina.');
  }

  const preferences = asObject(profile.preferences);
  const weekStart = mondayKey(new Date());
  const storedPlan = preferences.trainingPlan;
  if (storedPlan?.weekStart === weekStart && storedPlan.generatedBy === 'fittrack-recommender-v2' && Array.isArray(storedPlan.days)) {
    return decoratePlan(storedPlan);
  }

  const trainingDays = clampDays(preferences.trainingDays);
  const goal = profile.objective;
  const fallbackGroups = GROUPS_BY_DAYS[trainingDays];
  const availableGroups = ['pecho', 'espalda', 'hombros', 'brazos', 'pierna', 'abdomen', 'cuerpo completo'];
  const safeGroups = groupsAllowedByProfile(availableGroups, profile);
  const orderedGroups = await suggestTrainingGroupOrder({
    goal,
    availableGroups: safeGroups,
    condition: getGeminiProfileContext(profile),
  });
  const groups = orderedGroups
    ? [...orderedGroups, ...fallbackGroups.filter((group) => safeGroups.includes(group) && !orderedGroups.includes(group))].slice(0, trainingDays)
    : fallbackGroups.filter((group) => safeGroups.includes(group)).slice(0, trainingDays);
  const days = await Promise.all(groups.map(async (group, index) => {
    const category = group === 'brazos' ? 'biceps' : group === 'cuerpo completo' ? undefined : group;
    const catalog = await listExercises({ group: category, goal, trainingPlace: profile.trainingLocation });
    const exercises = catalog.slice(0, 4).map((exercise) => ({
      slug: exercise.slug,
      name: exercise.name,
      muscleCategory: exercise.muscleCategory,
      primaryMuscle: exercise.primaryMuscles?.[0] ?? '',
      description: exercise.description ?? '',
      imageUrl: exercise.images?.female ?? exercise.images?.male ?? null,
      instructions: exercise.instructions ?? [],
      sets: exercise.recommendation?.sets ?? 3,
      repetitions: exercise.recommendation?.repetitions ?? '8-12',
      focus: exercise.recommendation?.focus ?? 'técnica y movimiento seguro',
    }));

    return {
      date: dateAfter(weekStart, index),
      dayLabel: dayLabel(index),
      muscleGroup: group,
      title: `${GROUP_LABELS[group] ?? 'Cuerpo completo'} · ${goalLabel(goal)}`,
      durationMinutes: goal === 'STRENGTH' ? 55 : 45,
      completed: false,
      exercises,
    };
  }));

  const trainingPlan = { weekStart, trainingDays, generatedBy: 'fittrack-recommender-v2', days };
  await prisma.userProfile.update({
    where: { userId },
    data: { preferences: { ...preferences, trainingDays, trainingPlan } },
  });
  return decoratePlan(trainingPlan);
}

function groupsAllowedByProfile(groups, profile) {
  const condition = [profile.injuries, profile.surgeries, profile.pain, profile.diseases]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();
  const blocked = new Set();
  if (/rodilla|knee|tobillo|ankle|cadera|hip|fémur|femur/.test(condition)) blocked.add('pierna');
  if (/hombro|shoulder|manguito|clavícula|clavicula/.test(condition)) blocked.add('hombros');
  if (/espalda|lumbar|columna|back|hernia/.test(condition)) blocked.add('espalda');
  if (/codo|elbow|muñeca|muneca|wrist/.test(condition)) blocked.add('brazos');
  return groups.filter((group) => !blocked.has(group) || group === 'cuerpo completo');
}

export async function completeTrainingDay(userId, date, completed) {
  const prisma = getPrismaClient();
  const profile = await prisma.userProfile.findUnique({ where: { userId } });
  const preferences = asObject(profile?.preferences);
  const plan = preferences.trainingPlan;
  if (!plan || !Array.isArray(plan.days) || !plan.days.some((day) => day.date === date)) {
    throw new AuthError(404, 'No hay una rutina activa para ese día.');
  }

  const days = plan.days.map((day) => day.date === date ? { ...day, completed: Boolean(completed) } : day);
  const nextPlan = { ...plan, days };
  await prisma.userProfile.update({
    where: { userId },
    data: { preferences: { ...preferences, trainingPlan: nextPlan } },
  });
  return decoratePlan(nextPlan);
}

function decoratePlan(plan) {
  return {
    weekStart: plan.weekStart,
    trainingDays: plan.trainingDays,
    generatedBy: plan.generatedBy,
    days: plan.days.map((day) => ({ ...day, completed: Boolean(day.completed) })),
  };
}

function asObject(value) {
  return value && typeof value === 'object' && !Array.isArray(value) ? value : {};
}

function clampDays(value) {
  const days = Number(value ?? 4);
  return Number.isInteger(days) && days >= 1 && days <= 7 ? days : 4;
}

function mondayKey(date) {
  const result = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = result.getUTCDay() || 7;
  result.setUTCDate(result.getUTCDate() - day + 1);
  return result.toISOString().slice(0, 10);
}

function dateAfter(start, offset) {
  const date = new Date(`${start}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + offset);
  return date.toISOString().slice(0, 10);
}

function dayLabel(index) {
  return ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][index];
}

function goalLabel(goal) {
  return {
    STRENGTH: 'Fuerza',
    WEIGHT_LOSS: 'Pérdida de grasa',
    MUSCLE_GAIN: 'Hipertrofia',
    GENERAL_FITNESS: 'General',
  }[goal] ?? 'General';
}
