import api from './client';
import type {
  Temple,
  TempleDetail,
  PaginatedResponse,
  SingleResponse,
  Comment,
} from '@/types';

export async function getTemples(params?: {
  page?: number;
  per?: number;
  q?: Record<string, string>;
}): Promise<PaginatedResponse<Temple>> {
  const searchParams = new URLSearchParams();
  if (params?.page) searchParams.set('page', String(params.page));
  if (params?.per) searchParams.set('per', String(params.per));
  if (params?.q) {
    Object.entries(params.q).forEach(([key, value]) => {
      searchParams.set(`q[${key}]`, value);
    });
  }
  const query = searchParams.toString();
  return api.get<PaginatedResponse<Temple>>(
    `/temples${query ? `?${query}` : ''}`,
  );
}

export async function getTemple(
  id: number,
): Promise<SingleResponse<TempleDetail>> {
  return api.get<SingleResponse<TempleDetail>>(`/temples/${id}`);
}

export async function getTempleComments(
  templeId: number,
): Promise<{ data: Comment[] }> {
  return api.get<{ data: Comment[] }>(`/temples/${templeId}/templecomments`);
}

export async function createTempleComment(
  templeId: number,
  body: string,
): Promise<{ data: Comment }> {
  return api.post<{ data: Comment }>(`/temples/${templeId}/templecomments`, {
    body,
  });
}

export async function deleteTempleComment(
  id: number,
): Promise<{ message: string }> {
  return api.delete<{ message: string }>(`/templecomments/${id}`);
}

export async function getTempleLikes(): Promise<{ data: Temple[] }> {
  return api.get<{ data: Temple[] }>('/temple_likes');
}

export async function createTempleLike(
  templeId: number,
): Promise<{ data: { id: number; temple_id: number } }> {
  return api.post<{ data: { id: number; temple_id: number } }>(
    '/temple_likes',
    { temple_id: templeId },
  );
}

export async function deleteTempleLike(
  id: number,
): Promise<{ message: string }> {
  return api.delete<{ message: string }>(`/temple_likes/${id}`);
}
