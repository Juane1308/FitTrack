import { searchStoredFoods } from './catalog-db.service.js';

const OPEN_FOOD_FACTS_BASE = 'https://world.openfoodfacts.org/api/v2';
const OPEN_FOOD_FACTS_SEARCH = 'https://world.openfoodfacts.org/cgi/search.pl';
const USDA_SEARCH = 'https://api.nal.usda.gov/fdc/v1/foods/search';
const USER_AGENT = 'FITTRACK/1.0 (academic project)';

export async function searchFoods({ search, meal = 'all', page = 1, pageSize = 20, preferDatabase = true } = {}) {
  if (preferDatabase) {
    const stored = await searchStoredFoods({ search, meal, page, pageSize });
    if (stored.data.length > 0) return stored;
  }

  if (!search?.trim() && meal === 'all') {
    const terms = ['pollo', 'arroz', 'aguacate', 'manzana', 'avena'];
    // Open Food Facts and USDA can rate-limit bursts of requests. Load the
    // initial catalogue one term at a time and keep successful results if a
    // single provider/term is temporarily unavailable.
    const responses = [];
    for (const term of terms) {
      try {
        responses.push(await searchFoods({
          search: term,
          meal,
          page: 1,
          pageSize: Math.ceil(pageSize / terms.length),
          preferDatabase: false,
        }));
      } catch (error) {
        console.warn(`[foods] No se pudo cargar el término "${term}": ${error.message}`);
      }
    }
    const foods = new Map();
    responses.flatMap((result) => result.data).forEach((food) => foods.set(food.id, food));
    if (foods.size === 0) return externalServiceError();
    return { count: foods.size, page, data: [...foods.values()].slice(0, pageSize) };
  }

  const fields = [
    'code',
    'product_name',
    'product_name_es',
    'categories_tags',
    'image_front_small_url',
    'nutriments',
  ].join(',');
  const mealTerms = {
    breakfast: 'desayuno avena huevo yogur cereal',
    lunch: 'almuerzo arroz pollo ensalada legumbres',
    dinner: 'cena pollo pescado ensalada sopa arroz',
  };
  const terms = [search?.trim(), mealTerms[meal]].filter(Boolean).join(' ');
  const params = new URLSearchParams({
    page: String(page),
    page_size: String(Math.min(pageSize, 50)),
    fields,
    sort_by: 'unique_scans_n',
    lc: 'es',
    cc: 'co',
  });
  if (terms) params.set('search_terms', terms);

  const searchUrl = terms
    ? `${OPEN_FOOD_FACTS_SEARCH}?${new URLSearchParams({
        action: 'process',
        json: '1',
        search_simple: '1',
        search_terms: terms,
        page: String(page),
        page_size: String(Math.min(pageSize, 50)),
        fields,
        lc: 'es',
      })}`
    : `${OPEN_FOOD_FACTS_BASE}/search?${params}`;
  const response = await fetch(searchUrl, {
    headers: { 'User-Agent': USER_AGENT },
  });
  if (!response.ok) return searchUsdaFoods({ search, meal, page, pageSize });

  const payload = await response.json();
  const data = (payload.products ?? []).map((product) => normalizeFood(product, meal)).filter((food) => food.name);
  if (data.length === 0) return searchUsdaFoods({ search, meal, page, pageSize });
  return {
    count: payload.count ?? 0,
    page: payload.page ?? page,
    data,
  };
}

async function searchUsdaFoods({ search, meal = 'all', page = 1, pageSize = 20 }) {
  const defaultTerms = {
    all: ['chicken', 'rice', 'avocado', 'apple'],
    breakfast: ['oats', 'egg', 'yogurt'],
    lunch: ['chicken', 'rice', 'beans'],
    dinner: ['fish', 'salmon', 'vegetables'],
  };
  const terms = search?.trim() ? [search.trim()] : (defaultTerms[meal] ?? defaultTerms.all);
  const responses = await Promise.all(terms.map((term) => {
    const params = new URLSearchParams({
      api_key: process.env.USDA_API_KEY || 'DEMO_KEY',
      query: term,
      pageNumber: String(page),
      pageSize: String(Math.min(Math.ceil(pageSize / terms.length), 25)),
    });
    return fetch(`${USDA_SEARCH}?${params}`, { headers: { 'User-Agent': USER_AGENT } });
  }));
  if (responses.some((item) => !item.ok)) return externalServiceError();
  const payloads = await Promise.all(responses.map((item) => item.json()));
  const foods = new Map();
  payloads.flatMap((payload) => payload.foods ?? []).forEach((food) => {
    const normalized = normalizeUsdaFood(food, meal);
    if (normalized.name) foods.set(normalized.id, normalized);
  });
  return { count: foods.size, page, data: [...foods.values()].slice(0, pageSize) };
}

export async function getFood(barcode) {
  const response = await fetch(
    `${OPEN_FOOD_FACTS_BASE}/product/${encodeURIComponent(barcode)}.json`,
    { headers: { 'User-Agent': USER_AGENT } },
  );

  if (response.status === 404) {
    const error = new Error('El alimento no está disponible.');
    error.statusCode = 404;
    throw error;
  }
  if (!response.ok) return externalServiceError();

  const payload = await response.json();
  if (payload.status !== 1 || !payload.product) {
    const error = new Error('El alimento no está disponible.');
    error.statusCode = 404;
    throw error;
  }
  return normalizeFood(payload.product, 'all');
}

function normalizeFood(product, requestedMeal = 'all') {
  const nutrients = product.nutriments ?? {};
  const categories = Array.isArray(product.categories_tags)
    ? product.categories_tags
        .map((category) => category.replace(/^[a-z]{2}:/, '').replaceAll('-', ' '))
        .slice(0, 2)
        .join(', ')
    : '';

  return {
    id: product.code ?? product._id ?? '',
    barcode: product.code ?? product._id ?? null,
    name: product.product_name_es || product.product_name || '',
    category: categories || 'Sin categoría',
    imageUrl: product.image_front_small_url ?? null,
    servingGrams: numberOrNull(nutrients.serving_size),
    calories: numberOrNull(nutrients['energy-kcal_100g'] ?? nutrients['energy-kcal']),
    fat: numberOrNull(nutrients.fat_100g ?? nutrients.fat),
    protein: numberOrNull(nutrients.proteins_100g ?? nutrients.proteins),
    carbohydrates: numberOrNull(
      nutrients.carbohydrates_100g ?? nutrients.carbohydrates,
    ),
    fiber: numberOrNull(nutrients.fiber_100g ?? nutrients.fiber),
    mealTime: requestedMeal === 'all' ? classifyMeal(`${product.product_name_es ?? ''} ${categories}`) : requestedMeal,
  };
}

function normalizeUsdaFood(food, requestedMeal = 'all') {
  const nutrients = new Map((food.foodNutrients ?? []).map((nutrient) => [nutrient.nutrientId, nutrient.value]));
  const name = translateUsdaName(food.description || '');
  return {
    id: String(food.fdcId ?? food.gtinUpc ?? ''),
    barcode: food.gtinUpc ?? null,
    name,
    category: usdaCategory(name),
    imageUrl: ingredientImageUrl(name),
    servingGrams: numberOrNull(food.servingSize),
    calories: numberOrNull(nutrients.get(1008)),
    fat: numberOrNull(nutrients.get(1004)),
    protein: numberOrNull(nutrients.get(1003)),
    carbohydrates: numberOrNull(nutrients.get(1005)),
    fiber: numberOrNull(nutrients.get(1079)),
    mealTime: requestedMeal,
  };
}

function translateUsdaName(value) {
  return value
    .replace(/\bchicken\b/gi, 'pollo')
    .replace(/\brice\b/gi, 'arroz')
    .replace(/\bavocado\b/gi, 'aguacate')
    .replace(/\bapple\b/gi, 'manzana')
    .replace(/\boats?\b/gi, 'avena')
    .replace(/\begg(s)?\b/gi, 'huevo$1')
    .replace(/\byogurt\b/gi, 'yogur')
    .replace(/\bbeans?\b/gi, 'frijoles')
    .replace(/\bsalmon\b/gi, 'salmón')
    .replace(/\bfish\b/gi, 'pescado')
    .replace(/\bvegetables?\b/gi, 'verduras');
}

function usdaCategory(name) {
  const value = name.toLowerCase();
  if (/chicken|pollo|beef|fish|pescado|salmon|salmón|egg|huevo|bean|frijol|lentil|lenteja|tofu|yogurt|yogur|turkey/.test(value)) return 'Proteínas magras';
  if (/rice|arroz|oat|avena|bread|pan|pasta|potato|papa|cereal|corn|maíz|maiz/.test(value)) return 'Carbohidratos';
  if (/avocado|aguacate|oil|aceite|nut|nuez|almond|almendra|seed|semilla|olive|oliva/.test(value)) return 'Grasas';
  if (/apple|manzana|banana|banano|orange|naranja|vegetable|verdura|spinach|espinaca|tomato|tomate|fruit|fruta|carrot|zanahoria/.test(value)) return 'Vitaminas y Minerales';
  return 'Alimentos';
}

function ingredientImageUrl(name) {
  const ingredient = name.toLowerCase().replace(/,.*$/, '').replace(/[^a-z0-9 ]/g, '').trim().replace(/\s+/g, '_');
  return ingredient ? `https://www.themealdb.com/images/ingredients/${ingredient}.png` : null;
}

function classifyMeal(value) {
  const text = value.toLowerCase();
  if (/avena|cereal|granola|yogur|yogurt|huevo|pan|tostada|leche|café/.test(text)) return 'breakfast';
  if (/arroz|pollo|carne|pescado|ensalada|lenteja|frijol|pasta|sopa/.test(text)) return 'lunch';
  return 'all';
}

function numberOrNull(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value !== 'string') return null;
  const parsed = Number.parseFloat(value.replace(',', '.'));
  return Number.isFinite(parsed) ? parsed : null;
}

function externalServiceError() {
  const error = new Error('No se pudo consultar el catálogo de alimentos.');
  error.statusCode = 502;
  throw error;
}
