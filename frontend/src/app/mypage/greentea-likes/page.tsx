'use client';

import { useState, useEffect } from 'react';
import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import GreenteaCard from '@/components/greentea/GreenteaCard';
import { getGreenteaLikes } from '@/lib/api/greenteas';
import type { Greentea } from '@/types';

export default function GreenteaLikesPage() {
  const { data: session, status } = useSession();
  const router = useRouter();
  const [greenteas, setGreenteas] = useState<Greentea[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/auth/login');
      return;
    }
    if (status === 'authenticated') {
      getGreenteaLikes()
        .then((res) => setGreenteas(res.data))
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
      <h1 className="mb-6 text-2xl font-bold">お気に入り抹茶店</h1>

      {greenteas.length > 0 ? (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {greenteas.map((greentea) => (
            <GreenteaCard
              key={greentea.id}
              greentea={{ ...greentea, liked_by_current_user: true, likes_count: 0 }}
            />
          ))}
        </div>
      ) : (
        <p className="py-12 text-center text-gray-500">
          お気に入りの抹茶店はまだありません
        </p>
      )}
    </div>
  );
}
