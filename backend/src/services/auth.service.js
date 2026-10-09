import { z } from 'zod';

import { getPrismaClient } from '../config/database.js';
import { sendVerificationEmail } from './email.service.js';
import { hashPassword, verifyPassword } from '../utils/password.js';
import { createOpaqueToken, createVerificationCode, hashToken } from '../utils/tokens.js';

const SESSION_DURATION_MS = 7 * 24 * 60 * 60 * 1000;
const RESET_DURATION_MS = 60 * 60 * 1000;
const VERIFICATION_DURATION_MS = 10 * 60 * 1000;
const MAX_VERIFICATION_ATTEMPTS = 5;

const registrationSchema = z.object({
  name: z.string({ message: 'El nombre es obligatorio.' }).trim().min(2, 'El nombre es obligatorio.').max(120),
  email: z.email('Ingresa un correo electrónico válido.').transform((value) => value.toLowerCase()),
  password: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres.').max(128),
  confirmPassword: z.string().min(1, 'Confirma tu contraseña.'),
  acceptTerms: z.literal(true, { error: 'Debes aceptar los términos y condiciones.' }),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Las contraseñas no coinciden.',
  path: ['confirmPassword'],
});

const loginSchema = z.object({
  email: z.email('Ingresa un correo electrónico válido.').transform((value) => value.toLowerCase()),
  password: z.string().min(1, 'La contraseña es obligatoria.'),
});

const recoverySchema = z.object({
  email: z.email('Ingresa un correo electrónico válido.').transform((value) => value.toLowerCase()),
});

const verificationSchema = z.object({
  email: z.email('Ingresa un correo electrónico válido.').transform((value) => value.toLowerCase()),
  code: z.string().regex(/^\d{6}$/, 'El código debe tener 6 dígitos.'),
});

export class AuthError extends Error {
  constructor(statusCode, message, details) {
    super(message);
    this.name = 'AuthError';
    this.statusCode = statusCode;
    this.details = details;
  }
}

function parse(schema, data) {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw new AuthError(400, 'Verifica la información ingresada.', result.error.issues.map((issue) => issue.message));
  }
  return result.data;
}

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    isActive: user.isActive,
  };
}

async function createSession(prisma, userId) {
  const token = createOpaqueToken();
  const expiresAt = new Date(Date.now() + SESSION_DURATION_MS);

  await prisma.authSession.create({
    data: {
      userId,
      tokenHash: hashToken(token),
      expiresAt,
    },
  });

  return { token, expiresAt };
}

async function createAndSendVerificationCode(prisma, user) {
  const code = createVerificationCode();

  await prisma.emailVerificationCode.create({
    data: {
      userId: user.id,
      codeHash: hashToken(code),
      expiresAt: new Date(Date.now() + VERIFICATION_DURATION_MS),
    },
  });

  await sendVerificationEmail({ email: user.email, name: user.name, code });
}

export async function registerUser(payload) {
  const data = parse(registrationSchema, payload);
  const prisma = getPrismaClient();
  const existingUser = await prisma.user.findUnique({ where: { email: data.email } });

  if (existingUser) {
    throw new AuthError(409, 'Este correo ya está registrado.');
  }

  const user = await prisma.user.create({
    data: {
      name: data.name,
      email: data.email,
      passwordHash: await hashPassword(data.password),
      isActive: false,
    },
  });

  await createAndSendVerificationCode(prisma, user);

  return { user: publicUser(user) };
}

export async function loginUser(payload) {
  const data = parse(loginSchema, payload);
  const prisma = getPrismaClient();
  const user = await prisma.user.findUnique({ where: { email: data.email } });

  if (!user) {
    throw new AuthError(401, 'Correo o contraseña incorrectos.');
  }

  if (!user.emailVerifiedAt) {
    throw new AuthError(403, 'Verifica tu correo antes de iniciar sesión.');
  }

  if (!user.isActive) {
    throw new AuthError(403, 'La cuenta no está activa.');
  }

  if (!(await verifyPassword(data.password, user.passwordHash))) {
    throw new AuthError(401, 'Correo o contraseña incorrectos.');
  }

  const session = await createSession(prisma, user.id);
  return { user: publicUser(user), ...session };
}

export async function logoutUser(token) {
  const prisma = getPrismaClient();
  const result = await prisma.authSession.updateMany({
    where: {
      tokenHash: hashToken(token),
      revokedAt: null,
    },
    data: { revokedAt: new Date() },
  });

  if (result.count === 0) {
    throw new AuthError(401, 'La sesión no es válida o ya fue cerrada.');
  }
}

export async function requestPasswordRecovery(payload) {
  const data = parse(recoverySchema, payload);
  const prisma = getPrismaClient();
  const user = await prisma.user.findUnique({ where: { email: data.email } });

  if (user?.isActive) {
    const token = createOpaqueToken();
    await prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        tokenHash: hashToken(token),
        expiresAt: new Date(Date.now() + RESET_DURATION_MS),
      },
    });
  }

  return {
    message: 'Se ha enviado el enlace de recuperación a tu correo.',
  };
}

export async function verifyEmail(payload) {
  const data = parse(verificationSchema, payload);
  const prisma = getPrismaClient();
  const user = await prisma.user.findUnique({ where: { email: data.email } });

  if (!user) {
    throw new AuthError(400, 'El código de verificación no es válido.');
  }

  if (user.emailVerifiedAt) {
    return { message: 'El correo ya está verificado.' };
  }

  const verification = await prisma.emailVerificationCode.findFirst({
    where: {
      userId: user.id,
      usedAt: null,
      expiresAt: { gt: new Date() },
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!verification || verification.attempts >= MAX_VERIFICATION_ATTEMPTS) {
    throw new AuthError(400, 'El código de verificación no es válido o expiró.');
  }

  if (hashToken(data.code) !== verification.codeHash) {
    await prisma.emailVerificationCode.update({
      where: { id: verification.id },
      data: { attempts: { increment: 1 } },
    });
    throw new AuthError(400, 'El código de verificación no es válido o expiró.');
  }

  await prisma.$transaction([
    prisma.emailVerificationCode.update({
      where: { id: verification.id },
      data: { usedAt: new Date() },
    }),
    prisma.user.update({
      where: { id: user.id },
      data: { emailVerifiedAt: new Date(), isActive: true },
    }),
  ]);

  return { message: 'Correo verificado correctamente.' };
}

export async function resendVerificationCode(payload) {
  const data = parse(recoverySchema, payload);
  const prisma = getPrismaClient();
  const user = await prisma.user.findUnique({ where: { email: data.email } });

  if (user && !user.emailVerifiedAt) {
    await createAndSendVerificationCode(prisma, user);
  }

  return { message: 'Si la cuenta existe, se ha enviado un nuevo código de verificación.' };
}

export function getBearerToken(request) {
  const header = request.get('authorization');
  if (!header?.startsWith('Bearer ')) {
    throw new AuthError(401, 'Debes iniciar sesión para realizar esta acción.');
  }
  return header.slice('Bearer '.length).trim();
}
