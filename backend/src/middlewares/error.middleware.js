export function notFoundMiddleware(_request, response) {
  return response.status(404).json({
    error: 'Ruta no encontrada.',
  });
}

export function errorMiddleware(error, _request, response, _next) {
  console.error('[backend-error]', error.message);
  const statusCode = Number.isInteger(error.statusCode) ? error.statusCode : 500;
  const payload = { error: statusCode < 500 ? error.message : 'Ocurrió un error interno. Intenta nuevamente.' };

  if (error.details && statusCode < 500) {
    payload.details = error.details;
  }

  return response.status(statusCode).json(payload);
}
