import {
  loginUser,
  logoutUser,
  registerUser,
  resendVerificationCode,
  requestPasswordRecovery,
  getBearerToken,
  verifyEmail,
} from '../services/auth.service.js';

export async function registerController(request, response, next) {
  try {
    const result = await registerUser(request.body);
    return response.status(201).json({ message: 'Cuenta creada correctamente. Revisa tu correo para verificarla.', ...result });
  } catch (error) {
    return next(error);
  }
}

export async function loginController(request, response, next) {
  try {
    const result = await loginUser(request.body);
    return response.json({ message: 'Inicio de sesión exitoso.', ...result });
  } catch (error) {
    return next(error);
  }
}

export async function logoutController(request, response, next) {
  try {
    await logoutUser(getBearerToken(request));
    return response.json({ message: 'Sesión cerrada correctamente.' });
  } catch (error) {
    return next(error);
  }
}

export async function passwordRecoveryController(request, response, next) {
  try {
    const result = await requestPasswordRecovery(request.body);
    return response.json(result);
  } catch (error) {
    return next(error);
  }
}

export async function verifyEmailController(request, response, next) {
  try {
    const result = await verifyEmail(request.body);
    return response.json(result);
  } catch (error) {
    return next(error);
  }
}

export async function resendVerificationController(request, response, next) {
  try {
    const result = await resendVerificationCode(request.body);
    return response.json(result);
  } catch (error) {
    return next(error);
  }
}
