import { PrismaNeon } from '@prisma/adapter-neon';
import { PrismaClient } from '@prisma/client';

import { env, hasDatabaseUrl } from './env.js';

let prismaClient;

export function getPrismaClient() {
  if (!hasDatabaseUrl()) {
    throw new Error('DATABASE_URL no está configurada. Completa backend/.env con la conexión pooled de Neon.');
  }

  if (!prismaClient) {
    const adapter = new PrismaNeon({ connectionString: env.DATABASE_URL });
    prismaClient = new PrismaClient({ adapter });
  }

  return prismaClient;
}

export async function checkDatabaseConnection() {
  const prisma = getPrismaClient();
  await prisma.$queryRaw`SELECT 1`;
}

export async function disconnectDatabase() {
  if (prismaClient) {
    await prismaClient.$disconnect();
    prismaClient = undefined;
  }
}
