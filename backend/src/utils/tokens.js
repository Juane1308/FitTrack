import { createHash, randomBytes, randomInt } from 'node:crypto';

export function createOpaqueToken() {
  return randomBytes(32).toString('hex');
}

export function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

export function createVerificationCode() {
  return String(randomInt(100000, 1000000));
}
