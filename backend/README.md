# Backend de autenticación FITTRACK

API REST mínima para registro, inicio de sesión, verificación de correo,
recuperación de contraseña y cierre de sesión.

## Configuración

1. Copia `.env.example` como `.env` y completa Neon y el proveedor de correo.
2. Ejecuta `npm ci`.
3. Ejecuta `npm run prisma:generate`.
4. Ejecuta `npm run prisma:migrate:deploy`.
5. Inicia el servidor con `npm start`.

La API queda disponible en `/api` y las rutas de autenticación en `/api/auth`.
