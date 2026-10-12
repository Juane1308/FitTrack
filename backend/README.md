# Backend de autenticación FITTRACK

API REST para autenticación y el catálogo informativo de nutrición de FITTRACK.

## Configuración

1. Copia `.env.example` como `.env` y completa Neon y el proveedor de correo.
2. Ejecuta `npm ci`.
3. Ejecuta `npm run prisma:generate`.
4. Ejecuta `npm run prisma:migrate:deploy`.
5. Inicia el servidor con `npm start`.

La API queda disponible en `/api`, las rutas de autenticación en `/api/auth` y
el catálogo en `/api/nutrition`.

## Catálogo de nutrición

El catálogo es estático y local: no necesita claves ni llamadas a APIs externas.
Las recetas están en `backend/data/nutrition/recipes.json`, basadas en conjuntos
públicos de Kaggle, con imágenes incluidas como assets locales. Los alimentos y
sus valores por 100 g están en `backend/data/nutrition/foods.json`, derivados de
USDA FoodData Central Foundation Foods (descarga del 30 de abril de 2026).

Fuentes: [Food Ingredients and Recipes Dataset with Images (Kaggle)](https://www.kaggle.com/datasets/pes12017000148/food-ingredients-and-recipe-dataset-with-images), bajo CC BY-SA 3.0; [Epicurious Recipes with Rating and Nutrition (Kaggle)](https://www.kaggle.com/datasets/hugodarwood/epirecipes), usado para valores nutricionales de referencia; y [USDA FoodData Central](https://fdc.nal.usda.gov/download-datasets/). La traducción de recetas se guarda en el JSON, de modo que la aplicación no depende de un servicio externo de traducción.
Rutas principales:

- `GET /api/nutrition/recipe-categories`
- `GET /api/nutrition/recipes?meal=desayunos`
- `GET /api/nutrition/recipes/:id`
- `GET /api/nutrition/food-categories`
- `GET /api/nutrition/foods?category=proteinas`

Si se usa un emulador Android, el cliente Flutter ya
apunta a `10.0.2.2:3000`; para un teléfono físico configura `FITTRACK_API_URL`
con la dirección IP local del equipo que ejecuta el backend.



