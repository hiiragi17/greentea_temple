'use client';

import { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { FiMapPin, FiPhone, FiClock, FiExternalLink } from 'react-icons/fi';
import { getGreentea } from '@/lib/api/greenteas';
import {
  createGreenteaComment,
  deleteGreenteaComment,
  createGreenteaLike,
  deleteGreenteaLike,
} from '@/lib/api/greenteas';
import LikeButton from '@/components/common/LikeButton';
import CommentSection from '@/components/common/CommentSection';
import type { GreenteaDetail } from '@/types';

export default function GreenteaDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const [greentea, setGreentea] = useState<GreenteaDetail | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getGreentea(Number(id))
      .then((res) => setGreentea(res.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <span className="loading loading-spinner loading-lg text-primary" />
      </div>
    );
  }

  if (!greentea) {
    return (
      <div className="container mx-auto px-4 py-20 text-center">
        <p className="text-gray-500">抹茶店が見つかりませんでした</p>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-4">
        <Link href="/greenteas" className="text-green-600 hover:underline">
          ← 抹茶店一覧に戻る
        </Link>
      </div>

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
        {/* Main Content */}
        <div className="lg:col-span-2">
          {greentea.img && (
            <img
              src={greentea.img}
              alt={greentea.name}
              className="mb-6 h-64 w-full rounded-lg object-cover md:h-96"
            />
          )}

          <div className="mb-4 flex items-start justify-between">
            <h1 className="text-2xl font-bold">{greentea.name}</h1>
            <LikeButton
              liked={greentea.liked_by_current_user}
              likesCount={greentea.likes_count}
              onLike={() => createGreenteaLike(greentea.id).then(() => {})}
              onUnlike={() => deleteGreenteaLike(greentea.id).then(() => {})}
            />
          </div>

          <div className="mb-4 flex flex-wrap gap-1">
            {greentea.genres.map((genre) => (
              <span key={genre.id} className="badge badge-primary badge-sm">
                {genre.name}
              </span>
            ))}
          </div>

          <p className="mb-6 whitespace-pre-wrap text-gray-700">
            {greentea.description}
          </p>

          {/* Info Table */}
          <div className="mb-8 overflow-x-auto">
            <table className="table">
              <tbody>
                <tr>
                  <td className="flex items-center gap-2 font-semibold">
                    <FiMapPin /> 住所
                  </td>
                  <td>{greentea.address}</td>
                </tr>
                <tr>
                  <td className="font-semibold">アクセス</td>
                  <td>{greentea.access}</td>
                </tr>
                {greentea.phone_number && (
                  <tr>
                    <td className="flex items-center gap-2 font-semibold">
                      <FiPhone /> 電話番号
                    </td>
                    <td>{greentea.phone_number}</td>
                  </tr>
                )}
                {greentea.business_hours && (
                  <tr>
                    <td className="flex items-center gap-2 font-semibold">
                      <FiClock /> 営業時間
                    </td>
                    <td>{greentea.business_hours}</td>
                  </tr>
                )}
                {greentea.holiday && (
                  <tr>
                    <td className="font-semibold">定休日</td>
                    <td>{greentea.holiday}</td>
                  </tr>
                )}
                {greentea.homepage && (
                  <tr>
                    <td className="flex items-center gap-2 font-semibold">
                      <FiExternalLink /> HP
                    </td>
                    <td>
                      <a
                        href={greentea.homepage}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-green-600 hover:underline"
                      >
                        {greentea.homepage}
                      </a>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* Comments */}
          <CommentSection
            comments={greentea.comments}
            onSubmit={(body) =>
              createGreenteaComment(greentea.id, body).then(() => {})
            }
            onDelete={(commentId) =>
              deleteGreenteaComment(commentId).then(() => {})
            }
          />
        </div>

        {/* Sidebar - Nearby Temples */}
        <div>
          <h2 className="mb-4 text-lg font-bold">近くの神社</h2>
          {greentea.nearby_temples.length > 0 ? (
            <div className="space-y-3">
              {greentea.nearby_temples.map((temple) => (
                <Link
                  key={temple.id}
                  href={`/temples/${temple.id}`}
                  className="card bg-base-100 block p-3 shadow-sm transition-shadow hover:shadow-md"
                >
                  <div className="flex items-center gap-3">
                    {temple.img && (
                      <img
                        src={temple.img}
                        alt={temple.name}
                        className="h-16 w-16 rounded object-cover"
                      />
                    )}
                    <div>
                      <p className="font-semibold">{temple.name}</p>
                      <p className="text-sm text-gray-500">
                        {temple.distance_meters}m
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
    </div>
  );
}
