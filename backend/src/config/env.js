import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z.string().trim().default(''),
  DIRECT_URL: z.string().trim().default(''),
  EMAIL_HOST: z.string().trim().default('smtp-relay.sendinblue.com'),
  EMAIL_PORT: z.coerce.number().int().min(1).max(65535).default(587),
  EMAIL_USER: z.string().trim().default(''),
  EMAIL_PASSWORD: z.string().trim().default(''),
  EMAIL_FROM: z.string().trim().default(''),
  BREVO_API_KEY: z.string().trim().default(''),
  GEMINI_API_KEY: z.string().trim().default(''),
  GEMINI_MODEL: z.string().trim().default('gemini-3.8-flash'),
  GEMINI_FALLBACK_MODEL: z.string().trim().default('gemini-3.5-flash-lite'),
});

export const env = envSchema.parse(process.env);

export function hasDatabaseUrl() {
  return env.DATABASE_URL.startsWith('postgres://') || env.DATABASE_URL.startsWith('postgresql://');
}

export function hasDirectUrl() {
  return env.DIRECT_URL.startsWith('postgres://') || env.DIRECT_URL.startsWith('postgresql://');
}
