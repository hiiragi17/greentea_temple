'use client';

import { Suspense, useState, useEffect, useCallback } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import TempleCard from '@/components/temple/TempleCard';
import Pagination from '@/components/common/Pagination';
import { getTemples } from '@/lib/api/temples';
import { getAreas } from '@/lib/api/common';
import type { Temple, PaginationMeta, Area } from '@/types';

export default function TemplesPage() {
  return (
    <Suspense
      fallback={
        <div className="flex justify-center py-12">
          <span className="loading loading-spinner loading-lg text-primary" />
        </div>
      }
    >
      <TemplesContent />
    </Suspense>
  );
}

function TemplesContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [temples, setTemples] = useState<Temple[]>([]);
  const [meta, setMeta] = useState<PaginationMeta | null>(null);
  const [areas, setAreas] = useState<Area[]>([]);
  const [keyword, setKeyword] = useState(searchParams.get('keyword') || '');
  const [selectedArea, setSelectedArea] = useState(
    searchParams.get('area') || '',
  );
  const [loading, setLoading] = useState(true);

  const page = Number(searchParams.get('page')) || 1;

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const q: Record<string, string> = {};
      if (keyword) q['name_cont'] = keyword;
      if (selectedArea) q['areas_id_eq'] = selectedArea;

      const res = await getTemples({ page, q });
      setTemples(res.data);
      setMeta(res.meta);
    } catch {
      // エラー処理
    } finally {
      setLoading(false);
    }
  }, [page, keyword, selectedArea]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    getAreas().then((res) => setAreas(res.data)).catch(() => {});
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const params = new URLSearchParams();
    if (keyword) params.set('keyword', keyword);
    if (selectedArea) params.set('area', selectedArea);
    params.set('page', '1');
    router.push(`/temples?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set('page', String(newPage));
    router.push(`/temples?${params.toString()}`);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="mb-6 text-2xl font-bold">神社一覧</h1>

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
          value={selectedArea}
          onChange={(e) => setSelectedArea(e.target.value)}
        >
          <option value="">エリアを選択</option>
          {areas.map((area) => (
            <option key={area.id} value={area.id}>
              {area.name}
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
            {temples.map((temple) => (
              <TempleCard key={temple.id} temple={temple} />
            ))}
          </div>
          {temples.length === 0 && (
            <p className="py-12 text-center text-gray-500">
              該当する神社が見つかりませんでした
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
