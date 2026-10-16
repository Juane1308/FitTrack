CREATE TYPE "Goal" AS ENUM ('STRENGTH', 'WEIGHT_LOSS', 'MUSCLE_GAIN', 'GENERAL_FITNESS');

CREATE TABLE "user_profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "objective" "Goal",
    "birth_date" DATE,
    "weight" DECIMAL(8,2),
    "height" DECIMAL(5,2),
    "sports_activity" VARCHAR(160),
    "training_location" VARCHAR(160),
    "injuries" TEXT,
    "pain" TEXT,
    "surgeries" TEXT,
    "diseases" TEXT,
    "allergies" TEXT,
    "notifications_enabled" BOOLEAN NOT NULL DEFAULT true,
    "privacy_enabled" BOOLEAN NOT NULL DEFAULT true,
    "preferences" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "user_profiles_user_id_key" ON "user_profiles"("user_id");

ALTER TABLE "user_profiles"
  ADD CONSTRAINT "user_profiles_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
