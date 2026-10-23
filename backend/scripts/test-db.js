import { checkDatabaseConnection, disconnectDatabase } from '../src/config/database.js';

try {
  await checkDatabaseConnection();
  console.log('Conexión a Neon PostgreSQL verificada correctamente.');
} catch (error) {
  console.error(`No fue posible conectar con Neon: ${error.message}`);
  process.exitCode = 1;
} finally {
  await disconnectDatabase();
}
