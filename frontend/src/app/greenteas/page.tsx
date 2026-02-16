'use client';

import { Suspense, useState, useEffect, useCallback } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import GreenteaCard from '@/components/greentea/GreenteaCard';
import Pagination from '@/components/common/Pagination';
import { getGreenteas } from '@/lib/api/greenteas';
import { getGenres } from '@/lib/api/common';
import type { Greentea, PaginationMeta, Genre } from '@/types';

export default function GreenteasPage() {
  return (
    <Suspense
      fallback={
        <div className="flex justify-center py-12">
          <span className="loading loading-spinner loading-lg text-primary" />
        </div>
      }
    >
      <GreenteasContent />
    </Suspense>
  );
}

function GreenteasContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [greenteas, setGreenteas] = useState<Greentea[]>([]);
  const [meta, setMeta] = useState<PaginationMeta | null>(null);
  const [genres, setGenres] = useState<Genre[]>([]);
  const [keyword, setKeyword] = useState(searchParams.get('keyword') || '');
  const [selectedGenre, setSelectedGenre] = useState(
    searchParams.get('genre') || '',
  );
  const [loading, setLoading] = useState(true);

  const page = Number(searchParams.get('page')) || 1;

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const q: Record<string, string> = {};
      if (keyword) q['name_cont'] = keyword;
      if (selectedGenre) q['genres_id_eq'] = selectedGenre;

      const res = await getGreenteas({ page, q });
      setGreenteas(res.data);
      setMeta(res.meta);
    } catch {
      // エラー処理
    } finally {
      setLoading(false);
    }
  }, [page, keyword, selectedGenre]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    getGenres().then((res) => setGenres(res.data)).catch(() => {});
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const params = new URLSearchParams();
    if (keyword) params.set('keyword', keyword);
    if (selectedGenre) params.set('genre', selectedGenre);
    params.set('page', '1');
    router.push(`/greenteas?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set('page', String(newPage));
    router.push(`/greenteas?${params.toString()}`);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="mb-6 text-2xl font-bold">抹茶店一覧</h1>

      {/* Search Form */}
      <form onSubmit={handleSearch} className="mb-8 flex flex-wrap gap-3">
        <input
          type="text"
          className="input input-bordered flex-1"
          placeholder="キーワードで検索..."
          value={keyword}
          onChange={(e) => setKeyword(e.target.value)}
        />
        <select
          className="select select-bordered"
          value={selectedGenre}
          onChange={(e) => setSelectedGenre(e.target.value)}
        >
          <option value="">ジャンルを選択</option>
          {genres.map((genre) => (
            <option key={genre.id} value={genre.id}>
              {genre.name}
            </option>
          ))}
        </select>
        <button type="submit" className="btn btn-primary">
          検索
        </button>
      </form>

      {/* Results */}
      {loading ? (
        <div className="flex justify-center py-12">
          <span className="loading loading-spinner loading-lg text-primary" />
        </div>
      ) : (
        <>
          {meta && (
            <p className="mb-4 text-sm text-gray-500">
              {meta.total_count}件中 {(meta.current_page - 1) * 12 + 1}〜
              {Math.min(meta.current_page * 12, meta.total_count)}件を表示
            </p>
          )}
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {greenteas.map((greentea) => (
              <GreenteaCard key={greentea.id} greentea={greentea} />
            ))}
          </div>
          {greenteas.length === 0 && (
            <p className="py-12 text-center text-gray-500">
              該当する抹茶店が見つかりませんでした
            </p>
          )}
          {meta && (
            <div className="mt-8">
              <Pagination meta={meta} onPageChange={handlePageChange} />
            </div>
          )}
        </>
      )}
    </div>
  );
}
