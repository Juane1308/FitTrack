import { Router } from 'express';

import { getMediaAsset } from '../services/media.service.js';

export const mediaRouter = Router();

mediaRouter.get('/:assetKey', async (request, response, next) => {
  try {
    const assetKey = String(request.params.assetKey ?? '').trim();
    if (!/^[a-z0-9-]+$/.test(assetKey)) {
      return response.status(400).json({ error: 'Identificador de imagen inválido.' });
    }

    const asset = await getMediaAsset(assetKey);
    if (!asset) return response.status(404).json({ error: 'Imagen no encontrada.' });

    response.set('Content-Type', asset.mimeType);
    response.set('Cache-Control', 'public, max-age=31536000, immutable');
    return response.send(asset.imageData);
  } catch (error) {
    return next(error);
  }
});
