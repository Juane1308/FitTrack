import { z } from 'zod';
import { randomUUID } from 'node:crypto';

import { getPrismaClient } from '../config/database.js';
import { AuthError } from './auth.service.js';

const progressEntrySchema = z.object({
  weight: z.coerce.number().positive().max(500),
  height: z.coerce.number().positive().max(3),
  recordedAt: z.string().date().optional(),
  targetWeight: z.coerce.number().positive().max(500).optional().nullable(),
});

const progressPhotoSchema = z.object({
  imageBase64: z.string().min(100).max(7_000_000),
  mimeType: z.enum(['image/jpeg', 'image/png', 'image/webp']),
  fileName: z.string().trim().max(180).optional(),
});

export async function getProgress(userId) {
  const prisma = getPrismaClient();
  const [profile, entries] = await Promise.all([
    prisma.userProfile.findUnique({ where: { userId } }),
    prisma.progressEntry.findMany({
      where: { userId },
      orderBy: { recordedAt: 'asc' },
      take: 52,
    }),
  ]);

  const preferences = asObject(profile?.preferences);
  const plan = asObject(preferences.trainingPlan);
  const days = Array.isArray(plan.days) ? plan.days : [];
  const serializedEntries = entries.map(serializeEntry);
  const photos = await getPhotos(userId);
  const weekStart = plan.weekStart ?? mondayKey(new Date());
  const weekEnd = dateAfter(weekStart, 7);
  const [weekActivities, recentActivities, lifetimeDuration] = await Promise.all([
    prisma.workoutActivity.findMany({
      where: { userId, performedOn: { gte: dateAtUtc(weekStart), lt: dateAtUtc(weekEnd) } },
      orderBy: { performedOn: 'asc' },
    }),
    prisma.workoutActivity.findMany({
      where: { userId },
      select: { performedOn: true },
      distinct: ['performedOn'],
      orderBy: { performedOn: 'desc' },
      take: 370,
    }),
    prisma.workoutActivity.aggregate({
      where: { userId },
      _sum: { durationSeconds: true },
    }),
  ]);
  const currentWeight = serializedEntries.at(-1)?.weight ?? numberOrNull(profile?.weight);
  const initialWeight = serializedEntries[0]?.weight ?? currentWeight;
  const activityDates = new Set(weekActivities.map((activity) => dateKey(activity.performedOn)));
  const planCompletedDates = days.filter((day) => day?.completed === true).map((day) => day.date);
  const completedDates = new Set([...activityDates, ...planCompletedDates]);
  const completedDays = completedDates.size;
  const plannedDays = Number(plan.trainingDays ?? profileTrainingDays(preferences));
  const weekly = buildWeekly(weekStart, days, weekActivities);
  const targetWeight = numberOrNull(preferences.targetWeight) ?? serializedEntries.at(-1)?.targetWeight ?? null;
  const completionPercent = currentWeight != null && targetWeight != null
    ? calculateCompletion(currentWeight, targetWeight)
    : null;
  const weekComplete = days.length > 0 && days.filter((day) => day?.planned !== false).every((day) => day?.completed === true);
  const hasCurrentWeekPhoto = photos.some((photo) => photo.weekStart === weekStart);
  const activitySeconds = weekActivities.reduce((total, activity) => total + activity.durationSeconds, 0);
  const legacyCompletedSeconds = days
    .filter((day) => day?.completed === true && !activityDates.has(day.date))
    .reduce((total, day) => total + Number(day.actualDurationSeconds ?? Number(day.durationMinutes ?? 0) * 60), 0);

  return {
    summary: {
      currentWeight,
      initialWeight,
      weightChange: currentWeight != null && initialWeight != null ? round(currentWeight - initialWeight) : null,
      bmi: currentWeight != null && numberOrNull(profile?.height) ? round(currentWeight / (numberOrNull(profile.height) ** 2)) : null,
      completedDays,
      plannedDays,
      weeklyProgress: plannedDays > 0 ? Math.min(1, completedDays / plannedDays) : 0,
      targetWeight,
      completionPercent,
      activeStreak: calculateStreak(new Set([
        ...recentActivities.map((activity) => dateKey(activity.performedOn)),
        ...planCompletedDates,
      ])),
      totalMinutes: minutesFromSeconds((lifetimeDuration._sum.durationSeconds ?? 0) + legacyCompletedSeconds),
      weeklyMinutes: minutesFromSeconds(activitySeconds + legacyCompletedSeconds),
    },
    entries: serializedEntries,
    weekly,
    photos,
    photoEligible: weekComplete && !hasCurrentWeekPhoto,
    photoMessage: !weekComplete
      ? 'Completa todos los entrenamientos de la semana para subir tu foto.'
      : hasCurrentWeekPhoto
        ? 'Ya registraste la foto de esta semana.'
        : 'Semana completada. Ya puedes registrar tu foto.',
  };
}

export async function createProgressEntry(userId, payload) {
  const result = progressEntrySchema.safeParse(payload ?? {});
  if (!result.success) {
    throw new AuthError(400, 'Revisa el peso y la altura registrados.', result.error.issues.map((issue) => issue.message));
  }

  const data = result.data;
  const recordedAt = data.recordedAt ? new Date(`${data.recordedAt}T12:00:00.000Z`) : new Date();
  const progress = await getPrismaClient().$transaction(async (transaction) => {
    const entry = await transaction.progressEntry.create({
      data: {
        userId,
        weight: data.weight,
        height: data.height,
        recordedAt,
        targetWeight: data.targetWeight ?? null,
        completionPercent: data.targetWeight
          ? calculateCompletion(data.weight, data.targetWeight)
          : null,
      },
    });

    await transaction.userProfile.updateMany({
      where: { userId },
      data: { weight: data.weight, height: data.height },
    });
    return entry;
  });

  return serializeEntry(progress);
}

export async function createProgressPhoto(userId, payload) {
  const result = progressPhotoSchema.safeParse(payload ?? {});
  if (!result.success) {
    throw new AuthError(400, 'La imagen no tiene un formato válido.', result.error.issues.map((issue) => issue.message));
  }

  const prisma = getPrismaClient();
  const profile = await prisma.userProfile.findUnique({ where: { userId } });
  const preferences = asObject(profile?.preferences);
  const plan = asObject(preferences.trainingPlan);
  const days = Array.isArray(plan.days) ? plan.days : [];
  const plannedDays = days.filter((day) => day?.planned !== false);
  if (plannedDays.length === 0 || !plannedDays.every((day) => day?.completed === true)) {
    throw new AuthError(400, 'Completa todos los entrenamientos de la semana antes de subir la foto.');
  }

  const weekStart = plan.weekStart ?? mondayKey(new Date());
  const weekDate = new Date(`${weekStart}T00:00:00.000Z`);
  const nextWeek = new Date(weekDate);
  nextWeek.setUTCDate(nextWeek.getUTCDate() + 7);
  const existing = await prisma.progressPhoto.findFirst({
    where: { userId, capturedAt: { gte: weekDate, lt: nextWeek } },
  });
  if (existing) throw new AuthError(409, 'Ya registraste la foto de esta semana.');

  const data = Buffer.from(result.data.imageBase64, 'base64');
  const fileId = randomUUID();
  const photo = await prisma.progressPhoto.create({
    data: {
      userId,
      fileId,
      storageKey: `progress/${userId}/${weekStart}/${fileId}`,
      mimeType: result.data.mimeType,
      sizeBytes: data.byteLength,
      imageData: data,
      capturedAt: new Date(),
    },
  });
  return serializePhoto(photo, weekStart);
}

async function getPhotos(userId) {
  const rows = await getPrismaClient().progressPhoto.findMany({
    where: { userId },
    orderBy: { capturedAt: 'desc' },
    take: 6,
  });
  return rows.map((photo) => serializePhoto(photo, mondayKey(photo.capturedAt)));
}

function buildWeekly(weekStart, days, activities) {
  const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  return labels.map((label, index) => {
    const date = dateAfter(weekStart, index);
    const day = days.find((item) => item?.date === date);
    const dayActivities = activities.filter((activity) => dateKey(activity.performedOn) === date);
    const recordedSeconds = dayActivities.reduce((total, activity) => total + activity.durationSeconds, 0);
    return {
      date,
      label,
      completed: day?.completed === true || dayActivities.length > 0,
      planned: Boolean(day) || dayActivities.length > 0,
      durationMinutes: recordedSeconds > 0
        ? minutesFromSeconds(recordedSeconds)
        : Number(day?.actualDurationSeconds != null
          ? minutesFromSeconds(day.actualDurationSeconds)
          : day?.durationMinutes ?? 0),
      muscleGroup: day?.muscleGroup ?? '',
    };
  });
}

function calculateStreak(dates) {
  const current = bogotaDateKey(new Date());
  let cursor = dates.has(current) ? current : addDate(current, -1);
  let streak = 0;
  while (dates.has(cursor)) {
    streak += 1;
    cursor = addDate(cursor, -1);
  }
  return streak;
}

function dateAtUtc(value) {
  return new Date(`${value}T00:00:00.000Z`);
}

function dateKey(value) {
  return value.toISOString().slice(0, 10);
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

function addDate(value, offset) {
  const date = dateAtUtc(value);
  date.setUTCDate(date.getUTCDate() + offset);
  return date.toISOString().slice(0, 10);
}

function dateAfter(start, offset) {
  return addDate(start, offset);
}

function minutesFromSeconds(seconds) {
  return seconds > 0 ? Math.max(1, Math.round(seconds / 60)) : 0;
}

function calculateCompletion(weight, targetWeight) {
  return Math.max(0, Math.min(100, 100 - (Math.abs(weight - targetWeight) / Math.max(weight, targetWeight)) * 100));
}

function serializeEntry(entry) {
  return {
    id: entry.id,
    date: entry.recordedAt.toISOString().slice(0, 10),
    weight: numberOrNull(entry.weight),
    height: numberOrNull(entry.height),
    targetWeight: numberOrNull(entry.targetWeight),
    completionPercent: numberOrNull(entry.completionPercent),
  };
}

function serializePhoto(photo, weekStart) {
  const imageData = photo.imageData ? Buffer.from(photo.imageData).toString('base64') : '';
  return {
    id: photo.id,
    weekStart,
    capturedAt: photo.capturedAt.toISOString(),
    mimeType: photo.mimeType,
    dataUrl: imageData ? `data:${photo.mimeType};base64,${imageData}` : null,
  };
}

function mondayKey(date) {
  const result = dateAtUtc(bogotaDateKey(date));
  const day = result.getUTCDay() || 7;
  result.setUTCDate(result.getUTCDate() - day + 1);
  return result.toISOString().slice(0, 10);
}

function profileTrainingDays(preferences) {
  const value = Number(preferences.trainingDays ?? 4);
  return Number.isInteger(value) && value >= 1 && value <= 7 ? value : 4;
}

function asObject(value) {
  return value && typeof value === 'object' && !Array.isArray(value) ? value : {};
}

function numberOrNull(value) {
  if (value == null) return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function round(value) {
  return Math.round(value * 100) / 100;
}
