import { getPersonalizedRecommendation } from '../services/recommendation.service.js';

export async function recommendationController(request, response, next) {
  try {
    const refresh = request.query.refresh === 'true';
    return response.json({ data: await getPersonalizedRecommendation(request.authUser.id, { refresh }) });
  } catch (error) {
    return next(error);
  }
}
