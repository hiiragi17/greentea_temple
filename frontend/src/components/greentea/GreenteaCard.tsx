import Link from 'next/link';
import { FiHeart, FiMapPin } from 'react-icons/fi';
import type { Greentea } from '@/types';

interface GreenteaCardProps {
  greentea: Greentea;
}

export default function GreenteaCard({ greentea }: GreenteaCardProps) {
  return (
    <Link href={`/greenteas/${greentea.id}`}>
      <div className="card bg-base-100 shadow-md transition-shadow hover:shadow-lg">
        {greentea.img && (
          <figure className="h-48 overflow-hidden">
            <img
              src={greentea.img}
              alt={greentea.name}
              className="h-full w-full object-cover"
            />
          </figure>
        )}
        <div className="card-body p-4">
          <h3 className="card-title text-base">{greentea.name}</h3>
          <p className="line-clamp-2 text-sm text-gray-600">
            {greentea.description}
          </p>
          <div className="flex items-center gap-1 text-sm text-gray-500">
            <FiMapPin size={14} />
            <span className="truncate">{greentea.address}</span>
          </div>
          <div className="mt-2 flex flex-wrap gap-1">
            {greentea.genres.map((genre) => (
              <span key={genre.id} className="badge badge-outline badge-sm">
                {genre.name}
              </span>
            ))}
          </div>
          <div className="mt-2 flex items-center gap-1 text-sm text-gray-500">
            <FiHeart size={14} />
            <span>{greentea.likes_count}</span>
          </div>
        </div>
      </div>
    </Link>
  );
}
