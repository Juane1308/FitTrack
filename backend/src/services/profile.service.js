import { z } from 'zod';

import { getPrismaClient } from '../config/database.js';
import { AuthError } from './auth.service.js';

const goalLabels = {
  STRENGTH: 'Ganar fuerza',
  WEIGHT_LOSS: 'Perder grasa',
  MUSCLE_GAIN: 'Ganar masa muscular',
  GENERAL_FITNESS: 'Mantenerme activo',
};

const goalEnums = {
  STRENGTH: 'STRENGTH',
  'Ganar fuerza': 'STRENGTH',
  WEIGHT_LOSS: 'WEIGHT_LOSS',
  'Perder grasa': 'WEIGHT_LOSS',
  MUSCLE_GAIN: 'MUSCLE_GAIN',
  'Ganar masa muscular': 'MUSCLE_GAIN',
  'Mejorar resistencia': 'GENERAL_FITNESS',
  GENERAL_FITNESS: 'GENERAL_FITNESS',
  'Mantenerme activo': 'GENERAL_FITNESS',
};

const profileSchema = z.object({
  goal: z.string().trim().min(2).max(80).optional(),
  weight: z.coerce.number().positive().max(500).optional(),
  height: z.coerce.number().positive().max(3).optional(),
  birthDate: z.string().date().optional().nullable(),
  sport: z.string().trim().max(160).optional(),
  trainingPlace: z.string().trim().max(160).optional(),
  injuries: z.string().trim().max(2000).optional(),
  pain: z.string().trim().max(2000).optional(),
  surgeries: z.string().trim().max(2000).optional(),
  diseases: z.string().trim().max(2000).optional(),
  allergies: z.string().trim().max(2000).optional(),
  trainingDays: z.coerce.number().int().min(1).max(7).optional(),
  notificationsEnabled: z.boolean().optional(),
  privateProfile: z.boolean().optional(),
});

export function publicProfile(profile) {
  if (!profile) return null;
  const preferences = profile.preferences && typeof profile.preferences === 'object'
    ? profile.preferences
    : {};
  return {
    id: profile.id,
    goal: goalLabels[profile.objective] ?? profile.objective ?? '',
    objective: profile.objective,
    birthDate: profile.birthDate?.toISOString().slice(0, 10) ?? null,
    weight: profile.weight == null ? null : Number(profile.weight),
    height: profile.height == null ? null : Number(profile.height),
    sport: profile.sportsActivity ?? '',
    trainingPlace: profile.trainingLocation ?? '',
    injuries: profile.injuries ?? '',
    pain: profile.pain ?? '',
    surgeries: profile.surgeries ?? '',
    diseases: profile.diseases ?? '',
    allergies: profile.allergies ?? '',
    trainingDays: Number(preferences.trainingDays ?? 4),
    notificationsEnabled: profile.notificationsEnabled,
    privateProfile: profile.privacyEnabled,
    isComplete: Boolean(profile.objective && profile.weight && profile.height),
  };
}

// Keep the Gemini context limited to the health-related fields the user
// explicitly authorized. Never include email, password, user id or profile id.
export function getGeminiProfileContext(profile) {
  if (!profile) return {};
  return Object.fromEntries(
    Object.entries({
      lesiones: profile.injuries,
      dolor: profile.pain,
      cirugias: profile.surgeries,
      enfermedades: profile.diseases,
      alergias: profile.allergies,
    }).filter(([, value]) => typeof value === 'string' && value.trim()),
  );
}

function parsePayload(payload) {
  const result = profileSchema.safeParse(payload ?? {});
  if (!result.success) {
    throw new AuthError(400, 'Revisa los datos del perfil.', result.error.issues.map((issue) => issue.message));
  }
  const data = result.data;
  const objective = data.goal ? goalEnums[data.goal] : undefined;
  if (data.goal && !objective) {
    throw new AuthError(400, 'Selecciona una meta válida.');
  }

  return {
    fields: {
    ...(objective ? { objective } : {}),
    ...(data.birthDate !== undefined ? { birthDate: data.birthDate ? new Date(data.birthDate) : null } : {}),
    ...(data.weight !== undefined ? { weight: data.weight } : {}),
    ...(data.height !== undefined ? { height: data.height } : {}),
    ...(data.sport !== undefined ? { sportsActivity: data.sport } : {}),
    ...(data.trainingPlace !== undefined ? { trainingLocation: data.trainingPlace } : {}),
    ...(data.injuries !== undefined ? { injuries: data.injuries } : {}),
    ...(data.pain !== undefined ? { pain: data.pain } : {}),
    ...(data.surgeries !== undefined ? { surgeries: data.surgeries } : {}),
    ...(data.diseases !== undefined ? { diseases: data.diseases } : {}),
    ...(data.allergies !== undefined ? { allergies: data.allergies } : {}),
    ...(data.notificationsEnabled !== undefined ? { notificationsEnabled: data.notificationsEnabled } : {}),
    ...(data.privateProfile !== undefined ? { privacyEnabled: data.privateProfile } : {}),
    },
    trainingDays: data.trainingDays,
  };
}

export async function getUserProfile(userId) {
  const prisma = getPrismaClient();
  return publicProfile(await prisma.userProfile.findUnique({ where: { userId } }));
}

export async function saveUserProfile(userId, payload) {
  const prisma = getPrismaClient();
  const current = await prisma.userProfile.findUnique({
    where: { userId },
    select: { preferences: true, objective: true },
  });
  const parsed = parsePayload(payload);
  const currentPreferences = current?.preferences && typeof current.preferences === 'object'
    ? current.preferences
    : {};
  const preferences = {
    ...currentPreferences,
    ...(parsed.trainingDays !== undefined ? { trainingDays: parsed.trainingDays } : {}),
  };
  if (
    (parsed.fields.objective && parsed.fields.objective !== current?.objective) ||
    (parsed.trainingDays !== undefined && parsed.trainingDays !== Number(currentPreferences.trainingDays ?? 4))
  ) {
    delete preferences.trainingPlan;
  }
  if (Object.keys(parsed.fields).length > 0 || parsed.trainingDays !== undefined) {
    delete preferences.aiRecommendation;
  }
  const profile = await prisma.userProfile.upsert({
    where: { userId },
    create: { userId, ...parsed.fields, preferences },
    update: { ...parsed.fields, preferences },
  });
  return publicProfile(profile);
}
