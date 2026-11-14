CREATE TABLE "media_assets" (
    "id" UUID NOT NULL,
    "asset_key" VARCHAR(160) NOT NULL,
    "mime_type" VARCHAR(100) NOT NULL,
    "image_data" BYTEA NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "media_assets_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "media_assets_asset_key_key" ON "media_assets"("asset_key");
