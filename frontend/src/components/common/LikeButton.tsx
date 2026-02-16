'use client';

import { useState } from 'react';
import { useSession } from 'next-auth/react';
import { FiHeart } from 'react-icons/fi';
import { FaHeart } from 'react-icons/fa';

interface LikeButtonProps {
  liked: boolean;
  likesCount: number;
  onLike: () => Promise<void>;
  onUnlike: () => Promise<void>;
}

export default function LikeButton({
  liked,
  likesCount,
  onLike,
  onUnlike,
}: LikeButtonProps) {
  const { data: session } = useSession();
  const [isLiked, setIsLiked] = useState(liked);
  const [count, setCount] = useState(likesCount);
  const [loading, setLoading] = useState(false);

  const handleClick = async () => {
    if (!session) {
      alert('ログインが必要です');
      return;
    }
    if (loading) return;

    setLoading(true);
    try {
      if (isLiked) {
        await onUnlike();
        setIsLiked(false);
        setCount((prev) => prev - 1);
      } else {
        await onLike();
        setIsLiked(true);
        setCount((prev) => prev + 1);
      }
    } catch {
      // エラー時は状態を戻さない（楽観的更新しない）
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      className={`btn btn-sm gap-1 ${isLiked ? 'btn-error text-white' : 'btn-outline'}`}
      onClick={handleClick}
      disabled={loading}
    >
      {isLiked ? <FaHeart /> : <FiHeart />}
      <span>{count}</span>
    </button>
  );
}
