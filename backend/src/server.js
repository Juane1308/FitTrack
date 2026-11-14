import { env } from './config/env.js';
import { disconnectDatabase } from './config/database.js';
import { createApp } from './app.js';

const app = createApp();
const server = app.listen(env.PORT, () => {
  console.log(`FITTRACK API ejecutándose en http://localhost:${env.PORT}`);
});

async function shutdown(signal) {
  console.log(`Recibida señal ${signal}. Cerrando backend...`);
  server.close(async () => {
    await disconnectDatabase();
    process.exit(0);
  });
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
