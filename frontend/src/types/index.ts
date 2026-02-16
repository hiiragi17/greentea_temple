// 抹茶店
export interface Greentea {
  id: number;
  name: string;
  description: string;
  address: string;
  access: string;
  phone_number?: string;
  business_hours?: string;
  holiday?: string;
  homepage?: string;
  closed?: number;
  img?: string;
  latitude: number;
  longitude: number;
  genres: Genre[];
  likes_count: number;
  liked_by_current_user: boolean;
}

export interface GreenteaDetail extends Greentea {
  nearby_temples: NearbyPlace[];
  comments: Comment[];
}

// 神社
export interface Temple {
  id: number;
  name: string;
  description: string;
  address: string;
  access: string;
  phone_number?: string;
  business_hours?: string;
  holiday?: string;
  homepage?: string;
  img?: string;
  latitude: number;
  longitude: number;
  areas: Area[];
  likes_count: number;
  liked_by_current_user: boolean;
}

export interface TempleDetail extends Temple {
  nearby_greenteas: NearbyPlace[];
  comments: Comment[];
}

// ジャンル
export interface Genre {
  id: number;
  name: string;
}

// エリア
export interface Area {
  id: number;
  name: string;
}

// コメント
export interface Comment {
  id: number;
  body: string;
  user: { id: number; name: string };
  own: boolean;
  created_at: string;
}

// 近隣スポット
export interface NearbyPlace {
  id: number;
  name: string;
  address: string;
  img?: string;
  distance_meters: number;
  latitude?: number;
  longitude?: number;
}

// ユーザー
export interface User {
  id: number;
  name: string;
  role: string;
}

// APIレスポンス
export interface PaginationMeta {
  current_page: number;
  total_pages: number;
  total_count: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: PaginationMeta;
}

export interface SingleResponse<T> {
  data: T;
}

// 近隣検索
export interface NearbySearchResult {
  greenteas: NearbyPlace[];
  temples: NearbyPlace[];
}
