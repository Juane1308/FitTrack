CREATE TABLE "workout_activities" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "routine_name" VARCHAR(160) NOT NULL,
    "duration_seconds" INTEGER NOT NULL,
    "performed_on" DATE NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workout_activities_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "workout_activities_user_id_performed_on_idx"
ON "workout_activities"("user_id", "performed_on");

ALTER TABLE "workout_activities"
ADD CONSTRAINT "workout_activities_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
