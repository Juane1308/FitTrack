import { getPrismaClient } from '../config/database.js';

export async function getMediaAsset(assetKey) {
  return getPrismaClient().mediaAsset.findUnique({
    where: { assetKey },
    select: { mimeType: true, imageData: true },
  });
}
