'use client';

import { useState, useCallback } from 'react';
import Link from 'next/link';
import { FiMapPin, FiNavigation } from 'react-icons/fi';
import { searchNearby } from '@/lib/api/common';
import type { NearbySearchResult } from '@/types';

export default function NearbyPage() {
  const [result, setResult] = useState<NearbySearchResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [radius, setRadius] = useState(1.5);

  const handleSearch = useCallback(() => {
    if (!navigator.geolocation) {
      setError('お使いのブラウザは位置情報に対応していません');
      return;
    }

    setLoading(true);
    setError(null);

    navigator.geolocation.getCurrentPosition(
      async (position) => {
        try {
          const res = await searchNearby(
            position.coords.latitude,
            position.coords.longitude,
            radius,
          );
          setResult(res.data);
        } catch {
          setError('検索に失敗しました');
        } finally {
          setLoading(false);
        }
      },
      () => {
        setError('位置情報の取得に失敗しました。位置情報の許可を確認してください');
        setLoading(false);
      },
    );
  }, [radius]);

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="mb-6 text-2xl font-bold">現在地から探す</h1>

      <div className="mb-8 flex flex-wrap items-end gap-4">
        <div className="form-control">
          <label className="label">
            <span className="label-text">検索範囲</span>
          </label>
          <select
            className="select select-bordered"
            value={radius}
            onChange={(e) => setRadius(Number(e.target.value))}
          >
            <option value={0.5}>500m以内</option>
            <option value={1}>1km以内</option>
            <option value={1.5}>1.5km以内</option>
            <option value={3}>3km以内</option>
          </select>
        </div>
        <button
          onClick={handleSearch}
          className="btn btn-primary"
          disabled={loading}
        >
          <FiNavigation />
          {loading ? '検索中...' : '現在地で検索'}
        </button>
      </div>

      {error && (
        <div className="alert alert-error mb-6">
          <span>{error}</span>
        </div>
      )}

      {result && (
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
          {/* Greenteas */}
          <div>
            <h2 className="mb-4 text-lg font-bold">
              近くの抹茶店 ({result.greenteas.length}件)
            </h2>
            {result.greenteas.length > 0 ? (
              <div className="space-y-3">
                {result.greenteas.map((place) => (
                  <Link
                    key={place.id}
                    href={`/greenteas/${place.id}`}
                    className="card bg-base-100 block p-4 shadow-sm transition-shadow hover:shadow-md"
                  >
                    <div className="flex items-center gap-3">
                      {place.img && (
                        <img
                          src={place.img}
                          alt={place.name}
                          className="h-16 w-16 rounded object-cover"
                        />
                      )}
                      <div className="flex-1">
                        <p className="font-semibold">{place.name}</p>
                        <p className="flex items-center gap-1 text-sm text-gray-500">
                          <FiMapPin size={12} />
                          {place.address}
                        </p>
                        <p className="text-sm font-medium text-green-600">
                          {place.distance_meters}m
                        </p>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <p className="text-sm text-gray-500">
                近くに抹茶店が見つかりませんでした
              </p>
            )}
          </div>

          {/* Temples */}
          <div>
            <h2 className="mb-4 text-lg font-bold">
              近くの神社 ({result.temples.length}件)
            </h2>
            {result.temples.length > 0 ? (
              <div className="space-y-3">
                {result.temples.map((place) => (
                  <Link
                    key={place.id}
                    href={`/temples/${place.id}`}
                    className="card bg-base-100 block p-4 shadow-sm transition-shadow hover:shadow-md"
                  >
                    <div className="flex items-center gap-3">
                      {place.img && (
                        <img
                          src={place.img}
                          alt={place.name}
                          className="h-16 w-16 rounded object-cover"
                        />
                      )}
                      <div className="flex-1">
                        <p className="font-semibold">{place.name}</p>
                        <p className="flex items-center gap-1 text-sm text-gray-500">
                          <FiMapPin size={12} />
                          {place.address}
                        </p>
                        <p className="text-sm font-medium text-green-600">
                          {place.distance_meters}m
                        </p>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <p className="text-sm text-gray-500">
                近くに神社が見つかりませんでした
              </p>
            )}
          </div>
        </div>
      )}

      {!result && !loading && (
        <div className="py-12 text-center">
          <FiMapPin className="mx-auto mb-4 text-6xl text-gray-300" />
          <p className="text-gray-500">
            「現在地で検索」ボタンを押すと、近くの抹茶店と神社を探します
          </p>
        </div>
      )}
    </div>
  );
}
