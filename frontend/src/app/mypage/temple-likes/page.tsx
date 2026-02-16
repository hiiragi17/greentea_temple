'use client';

import { useState, useEffect } from 'react';
import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import TempleCard from '@/components/temple/TempleCard';
import { getTempleLikes } from '@/lib/api/temples';
import type { Temple } from '@/types';

export default function TempleLikesPage() {
  const { data: session, status } = useSession();
  const router = useRouter();
  const [temples, setTemples] = useState<Temple[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/auth/login');
      return;
    }
    if (status === 'authenticated') {
      getTempleLikes()
        .then((res) => setTemples(res.data))
        .catch(() => {})
        .finally(() => setLoading(false));
    }
  }, [status, router]);

  if (status === 'loading' || loading) {
    return (
      <div className="flex justify-center py-20">
        <span className="loading loading-spinner loading-lg text-primary" />
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="mb-6 text-2xl font-bold">お気に入り神社</h1>

      {temples.length > 0 ? (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {temples.map((temple) => (
            <TempleCard
              key={temple.id}
              temple={{ ...temple, liked_by_current_user: true, likes_count: 0 }}
            />
          ))}
        </div>
      ) : (
        <p className="py-12 text-center text-gray-500">
          お気に入りの神社はまだありません
        </p>
      )}
    </div>
  );
}
