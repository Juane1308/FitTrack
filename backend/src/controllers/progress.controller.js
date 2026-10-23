import { createProgressEntry, createProgressPhoto, getProgress } from '../services/progress.service.js';

export async function progressController(request, response, next) {
  try {
    return response.json({ data: await getProgress(request.authUser.id) });
  } catch (error) {
    return next(error);
  }
}

export async function createProgressEntryController(request, response, next) {
  try {
    return response.status(201).json({ data: await createProgressEntry(request.authUser.id, request.body) });
  } catch (error) {
    return next(error);
  }
}

export async function createProgressPhotoController(request, response, next) {
  try {
    return response.status(201).json({ data: await createProgressPhoto(request.authUser.id, request.body) });
  } catch (error) {
    return next(error);
  }
}
