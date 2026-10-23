import { getHealthStatus } from '../services/health.service.js';

export async function healthController(_request, response) {
  const health = await getHealthStatus();
  const statusCode = health.database === 'connected' ? 200 : 503;
  return response.status(statusCode).json(health);
}
