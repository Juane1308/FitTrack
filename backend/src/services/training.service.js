import { z } from 'zod';

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

const workoutActivitySchema = z.object({
  routineName: z.string().trim().min(1).max(160),
  durationSeconds: z.coerce.number().int().min(1).max(86_400),
  performedOn: z.string().date(),
});

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
      level: exercise.level ?? 'intermediate',
      muscleCategory: exercise.muscleCategory,
      primaryMuscle: exercise.primaryMuscles?.[0] ?? '',
      description: exercise.description ?? '',
      imageUrl: firstExerciseImage(exercise.images),
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

function firstExerciseImage(images) {
  if (typeof images === 'string') return images;
  if (Array.isArray(images)) return images.find((image) => typeof image === 'string') ?? null;
  if (!images || typeof images !== 'object') return null;
  return images.female ?? images.male ?? images.front ?? images.back ?? null;
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

export async function recordWorkoutActivity(userId, payload) {
  const result = workoutActivitySchema.safeParse(payload ?? {});
  if (!result.success) {
    throw new AuthError(400, 'No se pudo registrar el entrenamiento.', result.error.issues.map((issue) => issue.message));
  }

  const { routineName, durationSeconds, performedOn } = result.data;
  const prisma = getPrismaClient();
  const activity = await prisma.$transaction(async (transaction) => {
    const profile = await transaction.userProfile.findUnique({ where: { userId } });
    if (!profile) throw new AuthError(404, 'No se encontró el perfil del usuario.');

    const preferences = asObject(profile.preferences);
    const plan = asObject(preferences.trainingPlan);
    const days = Array.isArray(plan.days) ? plan.days : [];
    const completedPlanDate = days.find((day) => day.date === performedOn)?.date;

    const record = await transaction.workoutActivity.create({
      data: {
        userId,
        routineName,
        durationSeconds,
        performedOn: new Date(`${performedOn}T12:00:00.000Z`),
      },
    });

    if (completedPlanDate) {
      const sameDate = await transaction.workoutActivity.aggregate({
        where: { userId, performedOn: new Date(`${completedPlanDate}T12:00:00.000Z`) },
        _sum: { durationSeconds: true },
      });
      const actualDurationSeconds = sameDate._sum.durationSeconds ?? durationSeconds;
      const nextDays = days.map((day) => day.date === completedPlanDate
        ? { ...day, completed: true, actualDurationSeconds }
        : day);
      await transaction.userProfile.update({
        where: { userId },
        data: { preferences: { ...preferences, trainingPlan: { ...plan, days: nextDays } } },
      });
    }

    return record;
  });

  return {
    id: activity.id,
    routineName: activity.routineName,
    durationSeconds: activity.durationSeconds,
    performedOn: activity.performedOn.toISOString().slice(0, 10),
  };
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
  const result = new Date(`${bogotaDateKey(date)}T00:00:00.000Z`);
  const day = result.getUTCDay() || 7;
  result.setUTCDate(result.getUTCDate() - day + 1);
  return result.toISOString().slice(0, 10);
}

function bogotaDateKey(date) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Bogota',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map(({ type, value }) => [type, value]));
  return `${values.year}-${values.month}-${values.day}`;
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
