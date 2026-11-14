-- Permite guardar de forma persistente la imagen de cierre semanal en PostgreSQL.
ALTER TABLE "progress_photos"
ADD COLUMN "image_data" BYTEA;
