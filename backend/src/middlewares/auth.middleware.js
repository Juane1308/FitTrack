import { getPrismaClient } from '../config/database.js';
import { AuthError, getBearerToken } from '../services/auth.service.js';
import { hashToken } from '../utils/tokens.js';

export async function requireAuth(request, _response, next) {
  try {
    const prisma = getPrismaClient();
    const session = await prisma.authSession.findFirst({
      where: {
        tokenHash: hashToken(getBearerToken(request)),
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
      include: { user: { include: { profile: true } } },
    });

    if (!session) {
      throw new AuthError(401, 'La sesión no es válida o ya fue cerrada.');
    }

    request.authUser = session.user;
    request.authSession = session;
    return next();
  } catch (error) {
    return next(error);
  }
}
