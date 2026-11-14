import { checkDatabaseConnection } from '../config/database.js';

export async function getHealthStatus() {
  try {
    await checkDatabaseConnection();
    return { status: 'ok', database: 'connected' };
  } catch {
    return { status: 'degraded', database: 'unavailable' };
  }
}
