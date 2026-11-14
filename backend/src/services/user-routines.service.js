import { z } from 'zod';

import { getPrismaClient } from '../config/database.js';
import { AuthError } from './auth.service.js';

const createRoutineSchema = z.object({
  name: z.string().trim().min(1).max(160),
  exerciseSlugs: z.array(z.string().trim().min(1).max(180)).min(1).max(100),
});

const savedRoutinesSchema = z.object({
  routineKeys: z.array(z.string().trim().min(1).max(200)).max(300),
});

function parse(schema, payload, message) {
  const result = schema.safeParse(payload ?? {});
  if (!result.success) {
    throw new AuthError(400, message, result.error.issues.map((issue) => issue.message));
  }
  return result.data;
}

function toCustomRoutine(routine) {
  return {
    id: routine.id,
    name: routine.name,
    exerciseSlugs: Array.isArray(routine.exerciseSlugs)
      ? routine.exerciseSlugs.filter((slug) => typeof slug === 'string')
      : [],
    createdAt: routine.createdAt.toISOString(),
  };
}

export async function listUserRoutines(userId) {
  const prisma = getPrismaClient();
  const routines = await prisma.userCustomRoutine.findMany({
    where: { userId },
    orderBy: [{ createdAt: 'desc' }, { name: 'asc' }],
  });
  return routines.map(toCustomRoutine);
}

export async function createUserRoutine(userId, payload) {
  const data = parse(createRoutineSchema, payload, 'Revisa la rutina y sus ejercicios.');
  const exerciseSlugs = [...new Set(data.exerciseSlugs)];
  if (exerciseSlugs.length !== data.exerciseSlugs.length) {
    throw new AuthError(400, 'La rutina contiene ejercicios repetidos.');
  }

  const prisma = getPrismaClient();
  const foundExercises = await prisma.exercise.findMany({
    where: { slug: { in: exerciseSlugs } },
    select: { slug: true },
  });
  if (foundExercises.length !== exerciseSlugs.length) {
    throw new AuthError(400, 'Uno o más ejercicios ya no están disponibles.');
  }

  try {
    const routine = await prisma.userCustomRoutine.create({
      data: { userId, name: data.name, exerciseSlugs },
    });
    return toCustomRoutine(routine);
  } catch (error) {
    if (error?.code === 'P2002') {
      throw new AuthError(409, 'Ya tienes una rutina con ese nombre.');
    }
    throw error;
  }
}

export async function deleteUserRoutine(userId, routineId) {
  const prisma = getPrismaClient();
  const result = await prisma.userCustomRoutine.deleteMany({
    where: { id: routineId, userId },
  });
  if (result.count === 0) {
    throw new AuthError(404, 'No se encontró esa rutina en tu cuenta.');
  }
}

export async function listSavedRoutineKeys(userId) {
  const prisma = getPrismaClient();
  const saved = await prisma.userSavedRoutine.findMany({
    where: { userId },
    select: { routineKey: true },
  });
  return saved.map((item) => item.routineKey);
}

export async function replaceSavedRoutineKeys(userId, payload) {
  const data = parse(savedRoutinesSchema, payload, 'Revisa tus rutinas guardadas.');
  const routineKeys = [...new Set(data.routineKeys)];
  const prisma = getPrismaClient();

  await prisma.$transaction(async (transaction) => {
    await transaction.userSavedRoutine.deleteMany({ where: { userId } });
    if (routineKeys.length > 0) {
      await transaction.userSavedRoutine.createMany({
        data: routineKeys.map((routineKey) => ({ userId, routineKey })),
      });
    }
  });

  return routineKeys;
}
