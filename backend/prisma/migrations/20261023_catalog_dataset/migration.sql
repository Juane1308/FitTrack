-- Campos opcionales para persistir los catálogos externos sin afectar los
-- registros de autenticación, perfiles ni rutinas existentes.
ALTER TABLE "exercises"
  ADD COLUMN "slug" VARCHAR(180),
  ADD COLUMN "description" TEXT,
  ADD COLUMN "muscle_category" VARCHAR(80),
  ADD COLUMN "primary_muscles" JSONB,
  ADD COLUMN "image_url" TEXT,
  ADD COLUMN "video_url" TEXT,
  ADD COLUMN "equipment" JSONB,
  ADD COLUMN "source" VARCHAR(80);

CREATE UNIQUE INDEX "exercises_slug_key" ON "exercises"("slug");

ALTER TABLE "recipes"
  ADD COLUMN "image_url" TEXT,
  ADD COLUMN "source_url" TEXT,
  ADD COLUMN "source" VARCHAR(80);
