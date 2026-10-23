import { getStoredExercise, listStoredExercises } from './catalog-db.service.js';

const EXERCISE_API_BASE = 'https://marcmayol.com/exercise-api/v1';

let exerciseIndexCache;

export async function listExercises({ group, goal, trainingPlace, preferDatabase = true } = {}) {
  const storedExercises = preferDatabase ? await listStoredExercises({ group }) : [];
  const exercises = storedExercises.length > 0 ? storedExercises : await getExerciseIndex();
  const normalizedGroup = group?.trim().toLowerCase();
  const recommendation = recommendationFor(goal);

  return exercises
    .filter((exercise) => !normalizedGroup
      || exercise.muscleCategory === normalizedGroup
      || (normalizedGroup === 'brazos' && ['biceps', 'triceps'].includes(exercise.muscleCategory)))
    .filter((exercise) => isAvailableAt(exercise, trainingPlace))
    .map((exercise) => ({ ...exercise, recommendation }));
}

export function inferExerciseGroup(text, section = '') {
  const value = `${text ?? ''} ${section ?? ''}`.toLowerCase();
  if (/bíceps|biceps/.test(value)) return 'biceps';
  if (/tríceps|triceps/.test(value)) return 'triceps';
  if (/brazo|brazos/.test(value)) return 'brazos';
  if (/hombro|hombros|deltoide|shoulder/.test(value)) return 'hombros';
  if (/espalda|dorsal|lat(?:s)?|trapecio|back/.test(value)) return 'espalda';
  if (/pecho|pectoral|pectorales|chest|press de banca/.test(value)) return 'pecho';
  if (/abdomen|abdominal|core|oblicuo/.test(value)) return 'abdomen';
  if (/pierna|piernas|cuádriceps|quadriceps|femoral|glúteo|gluteo|pantorrilla/.test(value)) return 'pierna';
  return undefined;
}

export function requestedExerciseCount(text) {
  const value = String(text ?? '').toLowerCase();
  const match = value.match(/(?:de|con|por lo menos|al menos)\s+(\d{1,2})\s+ejercicios?|(?:rutina|entrenamiento)\s+(\d{1,2})\s+ejercicios?/);
  const count = Number(match?.[1] ?? match?.[2]);
  return Number.isInteger(count) && count >= 1 && count <= 16 ? count : null;
}

export async function getExercise(slug) {
  const storedExercise = await getStoredExercise(slug);
  if (storedExercise) return storedExercise;

  const safeSlug = encodeURIComponent(slug);
  const response = await fetch(`${EXERCISE_API_BASE}/exercises/${safeSlug}.json`);

  if (response.status === 404) {
    const error = new Error('El ejercicio no está disponible.');
    error.statusCode = 404;
    throw error;
  }

  if (!response.ok) {
    const error = new Error('No se pudo consultar el catálogo de ejercicios.');
    error.statusCode = 502;
    throw error;
  }

  return normalizeExercise(await response.json());
}

async function getExerciseIndex() {
  if (exerciseIndexCache) return exerciseIndexCache;

  const response = await fetch(`${EXERCISE_API_BASE}/exercises.json`);
  if (!response.ok) {
    const error = new Error('No se pudo consultar el catálogo de ejercicios.');
    error.statusCode = 502;
    throw error;
  }

  const payload = await response.json();
  const items = Array.isArray(payload)
    ? payload
    : Array.isArray(payload.exercises)
      ? payload.exercises
      : Object.values(payload);

  exerciseIndexCache = items
    .filter((item) => item && typeof item === 'object')
    .map(normalizeExercise)
    .filter((exercise) => exercise.slug && exercise.name);

  return exerciseIndexCache;
}

function normalizeExercise(exercise) {
  const name = localizedValue(exercise.name) || exercise.title || exercise.slug;
  const group = localizedValue(exercise.group) || '';
  const primaryMuscles = Array.isArray(exercise.primaryMuscles ?? exercise.muscles)
    ? (exercise.primaryMuscles ?? exercise.muscles).map((muscle) => localizeMuscle(localizedValue(muscle))).filter(Boolean)
    : [];
  const instructions = Array.isArray(exercise.instructions?.es)
    ? exercise.instructions.es
    : Array.isArray(exercise.instructions)
      ? exercise.instructions
      : [];

  return {
    slug: exercise.slug ?? exercise.id ?? '',
    name,
    group,
    primaryMuscles,
    instructions,
    description: typeof exercise.description === 'string' ? exercise.description : buildDescription(group, primaryMuscles),
    equipment: equipmentValue(exercise.equipment),
    images: exercise.images ?? exercise.image ?? {},
    muscleMap: exercise.muscleMap ?? null,
    muscleCategory: muscleCategory([...primaryMuscles, group, name]),
  };
}

function equipmentValue(value) {
  if (typeof value === 'string') return { id: value.toLowerCase(), name: value };
  if (!value || typeof value !== 'object') return null;
  return {
    id: value.id ?? '',
    name: localizedValue(value) || value.name || value.id || '',
  };
}

function isAvailableAt(exercise, trainingPlace) {
  const place = String(trainingPlace ?? '').trim().toLowerCase();
  if (!place || /gimnasio|gym/.test(place)) return true;

  const equipment = `${exercise.equipment?.id ?? ''} ${exercise.equipment?.name ?? ''}`.toLowerCase();
  // If the index does not expose equipment, keep the entry instead of hiding
  // a valid exercise. Full exercise cards still provide the technique/images.
  if (!equipment.trim()) return true;
  const bodyweight = /bodyweight|peso corporal|none|sin equipo|no equipment|calistenia/.test(equipment);
  const portable = /band|banda|elastic|elástico|dumbbell|mancuerna|kettlebell|mat|colchoneta/.test(equipment);
  const fixed = /machine|máquina|cable|polea|barbell|barra|smith|rack|bench|banco|leg press/.test(equipment);

  if (/casa|hogar|home/.test(place)) return bodyweight || portable || !fixed;
  if (/aire|exterior|parque|outdoor/.test(place)) return bodyweight || /band|banda|elastic|elástico/.test(equipment);
  return true;
}

function buildDescription(group, primaryMuscles) {
  const target = primaryMuscles.length > 0 ? primaryMuscles.join(', ') : 'la zona seleccionada';
  return `Ejercicio de ${group || 'entrenamiento'} enfocado en ${target}.`;
}

function localizeMuscle(value) {
  return {
    chest: 'Pecho',
    back: 'Espalda',
    shoulder: 'Hombros',
    shoulders: 'Hombros',
    biceps: 'Bíceps',
    triceps: 'Tríceps',
    quadriceps: 'Cuádriceps',
    hamstrings: 'Isquiotibiales',
    gluteal: 'Glúteos',
    calves: 'Pantorrillas',
    abdominals: 'Abdomen',
    abdomen: 'Abdomen',
    forearms: 'Antebrazos',
  }[value.toLowerCase()] ?? value;
}

function muscleCategory(values) {
  const text = values.join(' ').toLowerCase();
  if (/biceps/.test(text)) return 'biceps';
  if (/triceps/.test(text)) return 'triceps';
  if (/shoulder|deltoid|hombro/.test(text)) return 'hombros';
  if (/back|lat|trap|rhomboid|espalda/.test(text)) return 'espalda';
  if (/chest|pectoral|pecho/.test(text)) return 'pecho';
  if (/abdom|oblique|core|abs|abdomen/.test(text)) return 'abdomen';
  if (/leg|quad|hamstring|glute|calf|thigh|pierna/.test(text)) return 'pierna';
  return 'general';
}

function recommendationFor(goal) {
  const normalized = String(goal ?? '').toUpperCase();
  if (normalized.includes('STRENGTH') || normalized.includes('FUERZA')) {
    return { goal: 'Ganar fuerza', sets: 4, repetitions: '4-8', focus: 'cargas controladas y descansos amplios' };
  }
  if (normalized.includes('MUSCLE') || normalized.includes('MASA')) {
    return { goal: 'Ganar masa muscular', sets: 3, repetitions: '8-12', focus: 'progresión gradual y técnica' };
  }
  if (normalized.includes('WEIGHT') || normalized.includes('GRASA')) {
    return { goal: 'Perder grasa', sets: 3, repetitions: '10-15', focus: 'circuitos moderados y constancia' };
  }
  return { goal: 'Mantenerme activo', sets: 3, repetitions: '8-12', focus: 'técnica y movimiento seguro' };
}

function localizedValue(value) {
  if (typeof value === 'string') return value;
  if (value && typeof value === 'object') {
    return value.es ?? value.en ?? Object.values(value)[0] ?? '';
  }
  return '';
}
