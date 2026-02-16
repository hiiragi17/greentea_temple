import Link from 'next/link';
import { FiHeart, FiMapPin } from 'react-icons/fi';
import type { Temple } from '@/types';

interface TempleCardProps {
  temple: Temple;
}

export default function TempleCard({ temple }: TempleCardProps) {
  return (
    <Link href={`/temples/${temple.id}`}>
      <div className="card bg-base-100 shadow-md transition-shadow hover:shadow-lg">
        {temple.img && (
          <figure className="h-48 overflow-hidden">
            <img
              src={temple.img}
              alt={temple.name}
              className="h-full w-full object-cover"
            />
          </figure>
        )}
        <div className="card-body p-4">
          <h3 className="card-title text-base">{temple.name}</h3>
          <p className="line-clamp-2 text-sm text-gray-600">
            {temple.description}
          </p>
          <div className="flex items-center gap-1 text-sm text-gray-500">
            <FiMapPin size={14} />
            <span className="truncate">{temple.address}</span>
          </div>
          <div className="mt-2 flex flex-wrap gap-1">
            {temple.areas.map((area) => (
              <span key={area.id} className="badge badge-outline badge-sm">
                {area.name}
              </span>
            ))}
          </div>
          <div className="mt-2 flex items-center gap-1 text-sm text-gray-500">
            <FiHeart size={14} />
            <span>{temple.likes_count}</span>
          </div>
        </div>
      </div>
    </Link>
  );
}
