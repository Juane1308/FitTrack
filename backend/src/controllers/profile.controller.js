import { getUserProfile, saveUserProfile } from '../services/profile.service.js';

export async function getProfileController(request, response, next) {
  try {
    return response.json({ data: await getUserProfile(request.authUser.id) });
  } catch (error) {
    return next(error);
  }
}

export async function updateProfileController(request, response, next) {
  try {
    return response.json({ data: await saveUserProfile(request.authUser.id, request.body) });
  } catch (error) {
    return next(error);
  }
}
