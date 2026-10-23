import { env } from '../config/env.js';

export async function askGemini({
  message,
  goal,
  section,
  exercises = [],
  exerciseCatalog = [],
  foods = [],
  condition = {},
  trainingPlace = '',
  requestedGroup = '',
  requestedCount = null,
}) {
  if (!env.GEMINI_API_KEY) {
    const error = new Error('El asistente de Gemini todavía no está configurado.');
    error.statusCode = 503;
    throw error;
  }

  const availableExercises = exerciseCatalog.length > 0 ? exerciseCatalog : exercises;
  const catalogContext = JSON.stringify({
    ejerciciosDelCatalogoFiltrado: availableExercises.slice(0, 16).map((item) => ({
      slug: item.slug,
      nombre: item.name,
      zona: item.muscleCategory,
      musculos: item.primaryMuscles,
      equipo: item.equipment,
      descripcion: item.description,
      tecnica: Array.isArray(item.instructions) ? item.instructions.slice(0, 3) : [],
      imagen: item.images?.female ?? item.images?.male ?? item.imageUrl,
      recomendacion: item.recommendation,
    })),
    alimentos: foods.slice(0, 12).map((item) => ({
      nombre: item.name,
      categoria: item.mealTime,
      calorias: item.calories,
      proteina: item.protein,
      imagen: item.imageUrl,
    })),
  });

  const prompt = [
    'Eres el asistente de FITTRACK y respondes siempre en español.',
    'Ayuda con ejercicios, nutrición y hábitos. Sé breve, claro y práctico.',
    `La meta seleccionada por el usuario es: ${goal || 'Mantenerme activo'}.`,
    `Entorno de entrenamiento del usuario: ${trainingPlace || 'No indicado'}.`,
    `Zona muscular solicitada o detectada: ${requestedGroup || 'No especificada'}.`,
    `Cantidad solicitada: ${requestedCount ?? 'No especificada'}.`,
    'No diagnostiques ni sustituyas a profesionales de salud. Si la pregunta requiere evaluar una lesión, cirugía, enfermedad o alergia, indica consultar a un profesional.',
    'No inventes datos nutricionales. Si faltan datos, dilo.',
    'Cuando la pregunta sea de entrenamiento, rutina o reemplazo: utiliza únicamente ejercicios del catálogo filtrado que aparece abajo. Si se solicita una cantidad concreta, devuelve exactamente esa cantidad sin repetir ejercicios. Conserva el nombre exacto del catálogo, explica brevemente la técnica disponible y, si solicitan un reemplazo, no devuelvas el ejercicio que se quiere cambiar. No inventes ejercicios, imágenes ni equipos.',
    `Condiciones y alergias declaradas por el usuario (contexto autorizado): ${JSON.stringify(condition)}. Usa estos datos solo para evitar recomendaciones potencialmente inseguras o alimentos con alergias; no los interpretes como diagnóstico ni los repitas innecesariamente en la respuesta.`,
    `Sección actual: ${section}.`,
    `Catálogo disponible: ${catalogContext}.`,
    `Pregunta del usuario: ${message.trim()}`,
  ].join('\n');

  return requestGemini(prompt, { temperature: 0.35, maxOutputTokens: 700 });
}

export async function suggestTrainingGroupOrder({ goal, availableGroups, condition = {} }) {
  if (!env.GEMINI_API_KEY) return null;
  const prompt = [
    'Eres el planificador de entrenamiento de FITTRACK.',
    'Responde únicamente JSON válido con esta forma: {"groups":["pecho", "espalda"]}.',
    `Meta: ${goal || 'GENERAL_FITNESS'}.`,
    `Zonas permitidas: ${availableGroups.join(', ')}.`,
    `Condiciones declaradas por el usuario (contexto autorizado): ${JSON.stringify(condition)}.`,
    'Ordena las zonas de entrenamiento de más adecuada a menos adecuada para esa meta.',
    'Usa las condiciones únicamente para evitar o relegar zonas potencialmente inseguras. No diagnostiques ni prescribas tratamientos; si hay riesgo, prioriza la seguridad y recomienda consultar a un profesional.',
  ].join('\n');

  try {
    const text = await requestGemini(prompt, {
      temperature: 0.2,
      maxOutputTokens: 180,
      responseMimeType: 'application/json',
    });
    const parsed = JSON.parse(text.replace(/^```json\s*/i, '').replace(/```$/i, '').trim());
    if (!Array.isArray(parsed.groups)) return null;
    const allowed = new Set(availableGroups);
    const groups = parsed.groups.filter((group) => allowed.has(group));
    return groups.length > 0 ? groups : null;
  } catch (error) {
    console.error('[gemini-plan-error]', error.message);
    return null;
  }
}

export async function suggestNutritionStrategy({ goal, foods = [], condition = {} }) {
  if (!env.GEMINI_API_KEY) return null;
  const prompt = [
    'Eres el asesor de nutrición de FITTRACK y respondes siempre en español.',
    'Responde únicamente JSON válido con esta forma: {"method":"", "summary":"", "meals":[""], "focusFoods":[""]}.',
    `Meta: ${goal || 'GENERAL_FITNESS'}.`,
    `Alimentos reales disponibles: ${JSON.stringify(foods.slice(0, 16).map((food) => ({
      nombre: food.name,
      categoria: food.category,
      calorias: food.calories,
      proteina: food.protein,
      carbohidratos: food.carbohydrates,
      grasa: food.fat,
    })))}.`,
    `Condiciones y alergias declaradas por el usuario (contexto autorizado): ${JSON.stringify(condition)}.`,
    'Excluye alimentos relacionados con alergias declaradas. Usa enfermedades, cirugías o dolor solo como precaución general y recomienda un profesional cuando corresponda; no diagnostiques ni prescribas tratamientos.',
    'Propón un método general de alimentación y ejemplos de distribución de comidas sin inventar valores nutricionales ni prescribir tratamientos.',
  ].join('\n');

  try {
    const text = await requestGemini(prompt, {
      temperature: 0.25,
      maxOutputTokens: 420,
      responseMimeType: 'application/json',
    });
    const parsed = JSON.parse(text.replace(/^```json\s*/i, '').replace(/```$/i, '').trim());
    if (typeof parsed.method !== 'string' || typeof parsed.summary !== 'string') return null;
    return {
      method: parsed.method,
      summary: parsed.summary,
      meals: Array.isArray(parsed.meals) ? parsed.meals.filter((item) => typeof item === 'string').slice(0, 6) : [],
      focusFoods: Array.isArray(parsed.focusFoods) ? parsed.focusFoods.filter((item) => typeof item === 'string').slice(0, 8) : [],
    };
  } catch (error) {
    console.error('[gemini-nutrition-error]', error.message);
    return null;
  }
}

export async function translateRecipeNames(recipes = []) {
  if (recipes.length === 0) return recipes;
  const prompt = [
    'Traduce al español los nombres de estas recetas sin cambiar su significado.',
    'Responde únicamente JSON válido con esta forma: [{"id":"", "name":""}].',
    JSON.stringify(recipes.map((recipe) => ({ id: recipe.id, name: recipe.name }))),
  ].join('\n');
  if (!env.GEMINI_API_KEY) return recipes.map(localizeRecipeName);
  try {
    const text = await requestGemini(prompt, { temperature: 0.1, maxOutputTokens: 1200, responseMimeType: 'application/json' });
    const translated = JSON.parse(text.replace(/^```json\s*/i, '').replace(/```$/i, '').trim());
    if (!Array.isArray(translated)) return recipes.map(localizeRecipeName);
    const names = new Map(translated.filter((item) => item?.id && item?.name).map((item) => [item.id, item.name]));
    return recipes.map((recipe) => ({
      ...localizeRecipeName(recipe),
      name: names.get(recipe.id) ?? localizeRecipeName(recipe).name,
    }));
  } catch (error) {
    console.error('[gemini-recipe-name-error]', error.message);
    return recipes.map(localizeRecipeName);
  }
}

export async function translateRecipeContent(recipe) {
  if (!env.GEMINI_API_KEY) return localizeRecipeContent(recipe);
  const prompt = [
    'Traduce al español el nombre, los ingredientes y las instrucciones de esta receta.',
    'Conserva cantidades y pasos. Responde únicamente JSON válido con esta forma: {"name":"", "ingredients":[""], "instructions":""}.',
    JSON.stringify({ name: recipe.name, ingredients: recipe.ingredients, instructions: recipe.instructions }),
  ].join('\n');
  try {
    const text = await requestGemini(prompt, { temperature: 0.1, maxOutputTokens: 1800, responseMimeType: 'application/json' });
    const translated = JSON.parse(text.replace(/^```json\s*/i, '').replace(/```$/i, '').trim());
    if (typeof translated.name !== 'string' || !Array.isArray(translated.ingredients) || typeof translated.instructions !== 'string') {
      return localizeRecipeContent(recipe);
    }
    return {
      ...localizeRecipeContent(recipe),
      name: translated.name,
      ingredients: translated.ingredients.filter((item) => typeof item === 'string'),
      instructions: translated.instructions,
    };
  } catch (error) {
    console.error('[gemini-recipe-content-error]', error.message);
    return localizeRecipeContent(recipe);
  }
}

function localizeRecipeName(recipe) {
  return { ...recipe, name: localizeRecipeText(recipe.name) };
}

function localizeRecipeContent(recipe) {
  return {
    ...recipe,
    name: localizeRecipeText(recipe.name),
    ingredients: (recipe.ingredients ?? []).map((item) => localizeRecipeText(item)),
    instructions: localizeRecipeText(recipe.instructions ?? ''),
  };
}

// TheMealDB is a real catalogue with many English records. This deterministic
// fallback keeps the app in Spanish when Gemini is unavailable or rate-limited.
// It intentionally translates culinary vocabulary while preserving quantities.
function localizeRecipeText(value) {
  if (typeof value !== 'string' || !value.trim()) return value;
  const replacements = [
    ['Teriyaki Chicken Casserole', 'Cazuela de pollo teriyaki'],
    ['Antiguan Breakfast (Chop Up and ‘Saltfish’)', 'Desayuno antiguano (picado con pescado salado)'],
    ['Bread omelette', 'Tortilla de pan'],
    ['Breakfast Potatoes', 'Papas para el desayuno'],
    ['English Breakfast', 'Desayuno inglés'],
    ['Full English Breakfast', 'Desayuno inglés completo'],
    ['Oatmeal pancakes', 'Panqueques de avena'],
    ['Fruit and Cream Cheese Breakfast Pastries', 'Pasteles de desayuno con fruta y queso crema'],
    ['Jamaican Cornmeal Porridge', 'Gachas jamaicanas de maíz'],
    ['Rømmegrøt – Norwegian Sour Cream Porridge', 'Rømmegrøt – gachas noruegas de crema agria'],
    ['Salmon Eggs Eggs Benedict', 'Huevos benedictinos con salmón'],
    ['Flija Layered Pancake / Crepe', 'Panqueque o crepa en capas Flija'],
    ['Dutch poffertjes (mini pancakes)', 'Poffertjes holandeses (mini panqueques)'],
    ['Chop Up', 'Picado'],
    ['Saltfish', 'Pescado salado'],
    ['Layered', 'En capas'],
    ['Pancake', 'Panqueque'],
    ['Crepe', 'Crepa'],
    ['Pastries', 'Pasteles'],
    ['pastries', 'pasteles'],
    ['Fruit', 'Fruta'],
    ['fruit', 'fruta'],
    ['English', 'Inglés'],
    ['english', 'inglés'],
    ['Dutch', 'Holandés'],
    ['dutch', 'holandés'],
    ['Norwegian', 'Noruego'],
    ['norwegian', 'noruego'],
    ['Cornmeal', 'Harina de maíz'],
    ['cornmeal', 'harina de maíz'],
    ['Oatmeal', 'Avena'],
    ['oatmeal', 'avena'],
    ['Sour Cream', 'Crema agria'],
    ['sour cream', 'crema agria'],
    ['Extra Virgin Olive Oil', 'Aceite de oliva extra virgen'],
    ['Garlic Clove', 'Diente de ajo'],
    ['black pepper', 'pimienta negra'],
    ['Black Pepper', 'Pimienta negra'],
    ['a drizzle of oil', 'un chorrito de aceite'],
    ['with a drizzle', 'con un chorrito'],
    ['White Bread', 'Pan blanco'],
    ['Red Wine Vinegar', 'Vinagre de vino tinto'],
    ['Tip the bread into a bowl', 'Pon el pan en un recipiente'],
    ['Leave to soak', 'Deja en remojo'],
    ['Blend the ingredients together', 'Mezcla los ingredientes'],
    ['Let the soup cool in the fridge', 'Deja enfriar la sopa en el refrigerador'],
    ['drizzle of oil', 'chorrito de aceite'],
    ['White', 'Blanco'],
    ['white', 'blanco'],
    ['Almonds', 'Almendras'],
    ['almonds', 'almendras'],
    ['Vinegar', 'Vinagre'],
    ['vinegar', 'vinagre'],
    ['Virgin', 'Virgen'],
    ['virgin', 'virgen'],
    ['Clove', 'Diente'],
    ['clove', 'diente'],
    ['ingredients', 'ingredientes'],
    ['Ingredients', 'Ingredientes'],
    ['together', 'juntos'],
    ['Together', 'Juntos'],
    ['bowl', 'recipiente'],
    ['Bowl', 'Recipiente'],
    ['Blend', 'Mezcla'],
    ['blend', 'mezcla'],
    ['soak', 'remojar'],
    ['Soak', 'Remoja'],
    ['minutes', 'minutos'],
    ['minute', 'minuto'],
    ['mins', 'min'],
    ['fridge', 'refrigerador'],
    ['Fridge', 'Refrigerador'],
    ['hours', 'horas'],
    ['hour', 'hora'],
    ['hr', 'h'],
    ['drizzle', 'chorrito'],
    ['oil', 'aceite'],
    ['Oil', 'Aceite'],
    ['some', 'un poco de'],
    ['Some', 'Un poco de'],
    ['Step', 'Paso'],
    ['step', 'paso'],
    ['over', 'sobre'],
    ['Over', 'Sobre'],
    ['into', 'en'],
    ['Into', 'En'],
    ['leave', 'deja'],
    ['Leave', 'Deja'],
    ['cool', 'enfriar'],
    ['Cool', 'Enfriar'],
    ['or so', 'aproximadamente'],
    ['Or so', 'Aproximadamente'],
    ['then', 'luego'],
    ['Then', 'Luego'],
    ['serve', 'sirve'],
    ['Serve', 'Sirve'],
    ['for', 'durante'],
    ['For', 'Durante'],
    ['tbsp', 'cucharada'],
    ['tsp', 'cucharadita'],
    ['Baked', 'Horneado'],
    ['baked', 'horneado'],
    ['Fried', 'Frito'],
    ['fried', 'frito'],
    ['Grilled', 'A la parrilla'],
    ['grilled', 'a la parrilla'],
    ['Roasted', 'Asado'],
    ['roasted', 'asado'],
    ['Creamy', 'Cremoso'],
    ['creamy', 'cremoso'],
    ['Spicy', 'Picante'],
    ['spicy', 'picante'],
    ['Sweet', 'Dulce'],
    ['sweet', 'dulce'],
    ['Sour', 'Ácido'],
    ['sour', 'ácido'],
    ['Soup', 'Sopa'],
    ['soup', 'sopa'],
    ['Salad', 'Ensalada'],
    ['salad', 'ensalada'],
    ['Breakfast', 'Desayuno'],
    ['breakfast', 'desayuno'],
    ['Lunch', 'Almuerzo'],
    ['lunch', 'almuerzo'],
    ['Dinner', 'Cena'],
    ['dinner', 'cena'],
    ['Omelette', 'Tortilla'],
    ['omelette', 'tortilla'],
    ['Pancakes', 'Panqueques'],
    ['pancakes', 'panqueques'],
    ['Porridge', 'Gachas'],
    ['porridge', 'gachas'],
    ['Pie', 'Pastel'],
    ['pie', 'pastel'],
    ['Casserole', 'Cazuela'],
    ['casserole', 'cazuela'],
    ['Curry', 'Curry'],
    ['curry', 'curry'],
    ['Noodles', 'Fideos'],
    ['noodles', 'fideos'],
    ['Noodle', 'Fideo'],
    ['noodle', 'fideo'],
    ['Prawns', 'Langostinos'],
    ['prawns', 'langostinos'],
    ['Prawn', 'Langostino'],
    ['prawn', 'langostino'],
    ['Chilli', 'Chile'],
    ['chilli', 'chile'],
    ['Chili', 'Chile'],
    ['chili', 'chile'],
    ['Herb', 'Hierbas'],
    ['herb', 'hierbas'],
    ['Garlic', 'Ajo'],
    ['garlic', 'ajo'],
    ['Chicken', 'Pollo'],
    ['chicken', 'pollo'],
    ['Beef', 'Carne de res'],
    ['beef', 'carne de res'],
    ['Pork', 'Cerdo'],
    ['pork', 'cerdo'],
    ['Salmon', 'Salmón'],
    ['salmon', 'salmón'],
    ['Fish', 'Pescado'],
    ['fish', 'pescado'],
    ['Shrimp', 'Camarón'],
    ['shrimp', 'camarón'],
    ['Eggs', 'Huevos'],
    ['eggs', 'huevos'],
    ['Egg', 'Huevo'],
    ['egg', 'huevo'],
    ['Vegetables', 'Verduras'],
    ['vegetables', 'verduras'],
    ['Brown Rice', 'Arroz integral'],
    ['brown rice', 'arroz integral'],
    ['Rice', 'Arroz'],
    ['rice', 'arroz'],
    ['Potatoes', 'Papas'],
    ['potatoes', 'papas'],
    ['Potato', 'Papa'],
    ['potato', 'papa'],
    ['Tomatoes', 'Tomates'],
    ['tomatoes', 'tomates'],
    ['Tomato', 'Tomate'],
    ['tomato', 'tomate'],
    ['Onions', 'Cebollas'],
    ['onions', 'cebollas'],
    ['Onion', 'Cebolla'],
    ['onion', 'cebolla'],
    ['Garlic', 'Ajo'],
    ['garlic', 'ajo'],
    ['Bread', 'Pan'],
    ['bread', 'pan'],
    ['Butter', 'Mantequilla'],
    ['butter', 'mantequilla'],
    ['Cheese', 'Queso'],
    ['cheese', 'queso'],
    ['Cream', 'Crema'],
    ['cream', 'crema'],
    ['Milk', 'Leche'],
    ['milk', 'leche'],
    ['Yogurt', 'Yogur'],
    ['yogurt', 'yogur'],
    ['Avocado', 'Aguacate'],
    ['avocado', 'aguacate'],
    ['Lemon', 'Limón'],
    ['lemon', 'limón'],
    ['Lime', 'Limón verde'],
    ['lime', 'limón verde'],
    ['Olive Oil', 'Aceite de oliva'],
    ['olive oil', 'aceite de oliva'],
    ['Soy Sauce', 'Salsa de soya'],
    ['soy sauce', 'salsa de soya'],
    ['Brown Sugar', 'Azúcar morena'],
    ['brown sugar', 'azúcar morena'],
    ['Ground Ginger', 'Jengibre molido'],
    ['ground ginger', 'jengibre molido'],
    ['Minced Garlic', 'Ajo picado'],
    ['minced garlic', 'ajo picado'],
    ['Cornstarch', 'Fécula de maíz'],
    ['cornstarch', 'fécula de maíz'],
    ['tablespoons', 'cucharadas'],
    ['tablespoon', 'cucharada'],
    ['teaspoons', 'cucharaditas'],
    ['teaspoon', 'cucharadita'],
    ['cups', 'tazas'],
    ['cup', 'taza'],
    ['ounces', 'onzas'],
    ['ounce', 'onza'],
    ['Preheat oven', 'Precalienta el horno'],
    ['preheat oven', 'precalienta el horno'],
    ['Spray', 'Rocía'],
    ['spray', 'rocía'],
    ['Combine', 'Mezcla'],
    ['combine', 'mezcla'],
    ['Bring to a boil', 'Lleva a ebullición'],
    ['bring to a boil', 'lleva a ebullición'],
    ['Remove lid', 'Retira la tapa'],
    ['remove lid', 'retira la tapa'],
    ['Meanwhile', 'Mientras tanto'],
    ['meanwhile', 'mientras tanto'],
    ['stir together', 'mezcla'],
    ['until smooth', 'hasta obtener una mezcla homogénea'],
    ['Once sauce is boiling', 'Cuando la salsa hierva'],
    ['add mixture', 'agrega la mezcla'],
    ['Place', 'Coloca'],
    ['place', 'coloca'],
    ['Pour', 'Vierte'],
    ['pour', 'vierte'],
    ['bake', 'hornea'],
    ['Bake', 'Hornea'],
    ['Remove from oven', 'Retira del horno'],
    ['remove from oven', 'retira del horno'],
    ['shred', 'desmenuza'],
    ['Shred', 'Desmenuza'],
    ['steam', 'cocina al vapor'],
    ['Steam', 'Cocina al vapor'],
    ['according to package directions', 'según las instrucciones del paquete'],
    ['water', 'agua'],
    ['salt', 'sal'],
    ['pepper', 'pimienta'],
    ['and', 'y'],
    ['with', 'con'],
    ['&', ' y '],
    ['small saucepan', 'cacerola pequeña'],
    ['prepared pan', 'molde preparado'],
    ['until cooked through', 'hasta que esté completamente cocido'],
    ['until the sauce starts to thicken', 'hasta que la salsa comience a espesar'],
    ['then serve', 'luego sirve'],
  ];
  return replacements.reduce((text, [from, to]) => {
    if (from === '&') return text.replaceAll(from, to);
    return text.replace(new RegExp(`\\b${escapeRegExp(from)}\\b`, 'gi'), to);
  }, value);
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function requestGemini(prompt, generationConfig) {
  const models = [...new Set([env.GEMINI_MODEL, env.GEMINI_FALLBACK_MODEL].filter(Boolean))];

  for (const [index, model] of models.entries()) {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: {
            ...generationConfig,
            ...(model.startsWith('gemini-3')
              ? { thinkingConfig: { thinkingLevel: 'low' } }
              : {}),
          },
        }),
        signal: AbortSignal.timeout(45000),
      },
    );

    if (!response.ok) {
      const details = await response.text();
      const canTryFallback = [429, 503].includes(response.status) && index < models.length - 1;
      console.error(`[gemini-error:${model}]`, details.slice(0, 500));
      if (canTryFallback) continue;

      const error = new Error(`Gemini no pudo responder (${response.status}).`);
      error.statusCode = response.status === 429 || response.status === 503 ? response.status : 502;
      throw error;
    }

    const payload = await response.json();
    const text = payload.candidates?.[0]?.content?.parts?.map((part) => part.text ?? '').join('').trim();
    if (!text) {
      const error = new Error('Gemini no devolvió una respuesta utilizable.');
      error.statusCode = 502;
      throw error;
    }
    return text;
  }

  throw new Error('Gemini no pudo responder con ninguno de los modelos configurados.');
}
