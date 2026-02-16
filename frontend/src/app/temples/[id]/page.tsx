'use client';

import { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { FiMapPin, FiPhone, FiClock, FiExternalLink } from 'react-icons/fi';
import { getTemple } from '@/lib/api/temples';
import {
  createTempleComment,
  deleteTempleComment,
  createTempleLike,
  deleteTempleLike,
} from '@/lib/api/temples';
import LikeButton from '@/components/common/LikeButton';
import CommentSection from '@/components/common/CommentSection';
import type { TempleDetail } from '@/types';

export default function TempleDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const [temple, setTemple] = useState<TempleDetail | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getTemple(Number(id))
      .then((res) => setTemple(res.data))
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

  if (!temple) {
    return (
      <div className="container mx-auto px-4 py-20 text-center">
        <p className="text-gray-500">神社が見つかりませんでした</p>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-4">
        <Link href="/temples" className="text-green-600 hover:underline">
          ← 神社一覧に戻る
        </Link>
      </div>

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
        {/* Main Content */}
        <div className="lg:col-span-2">
          {temple.img && (
            <img
              src={temple.img}
              alt={temple.name}
              className="mb-6 h-64 w-full rounded-lg object-cover md:h-96"
            />
          )}

          <div className="mb-4 flex items-start justify-between">
            <h1 className="text-2xl font-bold">{temple.name}</h1>
            <LikeButton
              liked={temple.liked_by_current_user}
              likesCount={temple.likes_count}
              onLike={() => createTempleLike(temple.id).then(() => {})}
              onUnlike={() => deleteTempleLike(temple.id).then(() => {})}
            />
          </div>

          <div className="mb-4 flex flex-wrap gap-1">
            {temple.areas.map((area) => (
              <span key={area.id} className="badge badge-primary badge-sm">
                {area.name}
              </span>
            ))}
          </div>

          <p className="mb-6 whitespace-pre-wrap text-gray-700">
            {temple.description}
          </p>

          {/* Info Table */}
          <div className="mb-8 overflow-x-auto">
            <table className="table">
              <tbody>
                <tr>
                  <td className="flex items-center gap-2 font-semibold">
                    <FiMapPin /> 住所
                  </td>
                  <td>{temple.address}</td>
                </tr>
                <tr>
                  <td className="font-semibold">アクセス</td>
                  <td>{temple.access}</td>
                </tr>
                {temple.phone_number && (
                  <tr>
                    <td className="flex items-center gap-2 font-semibold">
                      <FiPhone /> 電話番号
                    </td>
                    <td>{temple.phone_number}</td>
                  </tr>
                )}
                {temple.business_hours && (
                  <tr>
                    <td className="flex items-center gap-2 font-semibold">
                      <FiClock /> 営業時間
                    </td>
                    <td>{temple.business_hours}</td>
                  </tr>
                )}
                {temple.holiday && (
                  <tr>
                    <td className="font-semibold">定休日</td>
                    <td>{temple.holiday}</td>
                  </tr>
                )}
                {temple.homepage && (
                  <tr>
                    <td className="flex items-center gap-2 font-semibold">
                      <FiExternalLink /> HP
                    </td>
                    <td>
                      <a
                        href={temple.homepage}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-green-600 hover:underline"
                      >
                        {temple.homepage}
                      </a>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* Comments */}
          <CommentSection
            comments={temple.comments}
            onSubmit={(body) =>
              createTempleComment(temple.id, body).then(() => {})
            }
            onDelete={(commentId) =>
              deleteTempleComment(commentId).then(() => {})
            }
          />
        </div>

        {/* Sidebar - Nearby Greenteas */}
        <div>
          <h2 className="mb-4 text-lg font-bold">近くの抹茶店</h2>
          {temple.nearby_greenteas.length > 0 ? (
            <div className="space-y-3">
              {temple.nearby_greenteas.map((greentea) => (
                <Link
                  key={greentea.id}
                  href={`/greenteas/${greentea.id}`}
                  className="card bg-base-100 block p-3 shadow-sm transition-shadow hover:shadow-md"
                >
                  <div className="flex items-center gap-3">
                    {greentea.img && (
                      <img
                        src={greentea.img}
                        alt={greentea.name}
                        className="h-16 w-16 rounded object-cover"
                      />
                    )}
                    <div>
                      <p className="font-semibold">{greentea.name}</p>
                      <p className="text-sm text-gray-500">
                        {greentea.distance_meters}m
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
      </div>
    </div>
  );
}
