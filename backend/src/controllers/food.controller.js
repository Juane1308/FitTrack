import { getFood, searchFoods } from '../services/food.service.js';

export async function searchFoodsController(request, response, next) {
  try {
    const page = Math.max(Number.parseInt(request.query.page ?? '1', 10) || 1, 1);
    const pageSize = Math.max(
      Math.min(Number.parseInt(request.query.pageSize ?? '20', 10) || 20, 50),
      1,
    );
    return response.json(
      await searchFoods({
        search: request.query.search,
        meal: request.query.meal,
        page,
        pageSize,
      }),
    );
  } catch (error) {
    return next(error);
  }
}

export async function getFoodController(request, response, next) {
  try {
    return response.json({ data: await getFood(request.params.barcode) });
  } catch (error) {
    return next(error);
  }
}
