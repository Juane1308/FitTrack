CREATE TABLE "user_custom_routines" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "exercise_slugs" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_custom_routines_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "user_saved_routines" (
    "user_id" UUID NOT NULL,
    "routine_key" VARCHAR(200) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_saved_routines_pkey" PRIMARY KEY ("user_id", "routine_key")
);

CREATE UNIQUE INDEX "user_custom_routines_user_id_name_key"
ON "user_custom_routines"("user_id", "name");

CREATE INDEX "user_custom_routines_user_id_created_at_idx"
ON "user_custom_routines"("user_id", "created_at");

CREATE INDEX "user_saved_routines_user_id_created_at_idx"
ON "user_saved_routines"("user_id", "created_at");

ALTER TABLE "user_custom_routines"
ADD CONSTRAINT "user_custom_routines_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_saved_routines"
ADD CONSTRAINT "user_saved_routines_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
