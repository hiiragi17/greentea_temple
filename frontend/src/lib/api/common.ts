import api from './client';
import type { Genre, Area, NearbySearchResult, User } from '@/types';

export async function getGenres(): Promise<{ data: Genre[] }> {
  return api.get<{ data: Genre[] }>('/genres');
}

export async function getAreas(): Promise<{ data: Area[] }> {
  return api.get<{ data: Area[] }>('/areas');
}

export async function searchNearby(
  lat: number,
  lng: number,
  radius?: number,
): Promise<{ data: NearbySearchResult }> {
  const params = new URLSearchParams({
    lat: String(lat),
    lng: String(lng),
  });
  if (radius) params.set('radius', String(radius));
  return api.get<{ data: NearbySearchResult }>(`/nearby?${params.toString()}`);
}

export async function getCurrentUser(): Promise<{ data: User }> {
  return api.get<{ data: User }>('/current_user');
}

export async function loginWithOAuth(
  provider: string,
  params: { code: string; uid: string; name?: string },
): Promise<{ data: { token: string; user: User } }> {
  return api.post<{ data: { token: string; user: User } }>(
    `/auth/${provider}`,
    params,
  );
}

export async function logout(): Promise<{ message: string }> {
  return api.delete<{ message: string }>('/auth/logout');
}
