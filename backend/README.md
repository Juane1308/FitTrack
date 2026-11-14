# FITTRACK Backend

API REST de FITTRACK construida con Node.js, Express, Prisma y Neon PostgreSQL.

## Arquitectura

```text
Flutter
  ↓ HTTP/JSON
Node.js + Express
  ↓ Prisma
Neon PostgreSQL
```

Flutter no se conecta directamente a Neon.

## Configuración local

1. Copia `.env.example` como `.env`.
2. Entra al panel de Neon y copia dos cadenas:
   - `DATABASE_URL`: conexión pooled, con `-pooler` en el host, para el runtime.
   - `DIRECT_URL`: conexión directa, sin `-pooler`, para Prisma CLI y migraciones.
3. Nunca subas `.env` a GitHub.

```powershell
cd backend
Copy-Item .env.example .env
```

## Instalación

```powershell
npm install
npm run prisma:generate
```

## Migraciones

Después de configurar `DIRECT_URL` en `.env`:

```powershell
npm run prisma:migrate -- --name init
```

Para aplicar migraciones existentes en otro entorno:

```powershell
npm run prisma:migrate:deploy
```

## Prueba de conexión

```powershell
npm run test:db
```

El resultado esperado es:

```text
Conexión a Neon PostgreSQL verificada correctamente.
```

Si no se ha configurado una cadena real, la prueba informa que falta `DATABASE_URL` y no expone credenciales.

## Ejecución

```powershell
npm run dev
```

Endpoints iniciales:

```text
GET http://localhost:3000/api
GET http://localhost:3000/api/health
GET http://localhost:3000/api/exercises
GET http://localhost:3000/api/exercises/:slug
GET http://localhost:3000/api/foods?search=avena
GET http://localhost:3000/api/foods/:barcode
```

La API de salud devuelve `database: connected` únicamente cuando Neon responde correctamente.

## Catálogos externos

El backend funciona como intermediario para que Flutter no consuma fuentes externas directamente:

- Ejercicios: API pública de Marc Mayol, con datos en español, músculos e instrucciones.
- Alimentos: Open Food Facts, con datos nutricionales e imágenes de productos.

Los resultados externos se normalizan antes de enviarse a Flutter. La aplicación consulta primero
los registros persistidos en Neon y, si todavía no existe un registro, utiliza la fuente externa
real correspondiente; nunca reemplaza el contenido por datos simulados.

Para persistir el catálogo en Neon después de aplicar las migraciones, ejecuta:

```powershell
npm run seed:catalog
```

El script guarda ejercicios, alimentos y recetas en las tablas `exercises`, `foods` y `recipes`.
Después de la carga, la API consulta primero esos registros de Neon y conserva las fuentes
externas como respaldo si una categoría todavía está vacía.

Open Food Facts solicita identificar el cliente mediante `User-Agent`; FITTRACK utiliza un
identificador básico de aplicación en las solicitudes de lectura. Revisa sus condiciones de
reutilización antes de publicar una versión comercial.

## Autenticación

La autenticación utiliza `crypto.scrypt` de Node.js para almacenar únicamente hashes de contraseña. Las sesiones se guardan en Neon como hashes de tokens revocables.

Endpoints disponibles:

```text
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/password-recovery
POST /api/auth/verify-email
POST /api/auth/resend-verification
```

El registro crea la cuenta como no activa, genera un código de 6 dígitos con vigencia de 10 minutos y lo envía mediante Brevo SMTP. El usuario debe verificar el correo antes de iniciar sesión.

Configura estas variables en `.env` para habilitar el envío:

```env
EMAIL_HOST=smtp-relay.brevo.com
EMAIL_PORT=587
EMAIL_USER=usuario_smtp_de_brevo
EMAIL_PASSWORD=smtp_key_de_brevo
EMAIL_FROM=correo_remitente_verificado
```

Ejemplo de registro:

```json
{
  "name": "Usuario FitTrack",
  "email": "usuario@example.com",
  "password": "ClaveSegura123",
  "confirmPassword": "ClaveSegura123",
  "acceptTerms": true
}
```

El login devuelve un token de sesión para enviarlo posteriormente como:

```text
Authorization: Bearer <token>
```

El endpoint de recuperación prepara el token de forma segura, pero el envío del correo requiere integrar posteriormente un proveedor de email. No se exponen tokens ni contraseñas en la respuesta.

## Despliegue en Railway

El backend está preparado para desplegarse como un servicio independiente dentro del monorepo.

1. Crea un proyecto nuevo en Railway e importa este repositorio.
2. En la configuración del servicio, establece `Root Directory` como `/backend`.
3. Railway detectará `backend/railway.json`, instalará las dependencias, generará Prisma y ejecutará `npm start`.
4. Configura en Railway las variables de `backend/.env.example`, usando valores reales para Neon y Brevo.
5. Ejecuta las migraciones antes de usar la API:

```powershell
npm run prisma:migrate:deploy
```

La URL pública resultante deberá terminar en `/api` cuando se configure Flutter, por ejemplo:

```text
https://tu-servicio.up.railway.app/api
```
