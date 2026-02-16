import api from './client';
import type {
  Greentea,
  GreenteaDetail,
  PaginatedResponse,
  SingleResponse,
  Comment,
} from '@/types';

export async function getGreenteas(params?: {
  page?: number;
  per?: number;
  q?: Record<string, string>;
}): Promise<PaginatedResponse<Greentea>> {
  const searchParams = new URLSearchParams();
  if (params?.page) searchParams.set('page', String(params.page));
  if (params?.per) searchParams.set('per', String(params.per));
  if (params?.q) {
    Object.entries(params.q).forEach(([key, value]) => {
      searchParams.set(`q[${key}]`, value);
    });
  }
  const query = searchParams.toString();
  return api.get<PaginatedResponse<Greentea>>(
    `/greenteas${query ? `?${query}` : ''}`,
  );
}

export async function getGreentea(
  id: number,
): Promise<SingleResponse<GreenteaDetail>> {
  return api.get<SingleResponse<GreenteaDetail>>(`/greenteas/${id}`);
}

export async function getGreenteaComments(
  greenteaId: number,
): Promise<{ data: Comment[] }> {
  return api.get<{ data: Comment[] }>(
    `/greenteas/${greenteaId}/greenteacomments`,
  );
}

export async function createGreenteaComment(
  greenteaId: number,
  body: string,
): Promise<{ data: Comment }> {
  return api.post<{ data: Comment }>(
    `/greenteas/${greenteaId}/greenteacomments`,
    { body },
  );
}

export async function deleteGreenteaComment(
  id: number,
): Promise<{ message: string }> {
  return api.delete<{ message: string }>(`/greenteacomments/${id}`);
}

export async function getGreenteaLikes(): Promise<{ data: Greentea[] }> {
  return api.get<{ data: Greentea[] }>('/greentea_likes');
}

export async function createGreenteaLike(
  greenteaId: number,
): Promise<{ data: { id: number; greentea_id: number } }> {
  return api.post<{ data: { id: number; greentea_id: number } }>(
    '/greentea_likes',
    { greentea_id: greenteaId },
  );
}

export async function deleteGreenteaLike(
  id: number,
): Promise<{ message: string }> {
  return api.delete<{ message: string }>(`/greentea_likes/${id}`);
}
