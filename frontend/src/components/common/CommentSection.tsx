'use client';

import { useState } from 'react';
import { useSession } from 'next-auth/react';
import type { Comment } from '@/types';

interface CommentSectionProps {
  comments: Comment[];
  onSubmit: (body: string) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}

export default function CommentSection({
  comments: initialComments,
  onSubmit,
  onDelete,
}: CommentSectionProps) {
  const { data: session } = useSession();
  const [comments, setComments] = useState(initialComments);
  const [body, setBody] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!body.trim() || submitting) return;

    setSubmitting(true);
    try {
      await onSubmit(body);
      setBody('');
      // 再取得は親コンポーネントに任せる
    } catch {
      alert('コメントの投稿に失敗しました');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('コメントを削除しますか？')) return;
    try {
      await onDelete(id);
      setComments((prev) => prev.filter((c) => c.id !== id));
    } catch {
      alert('コメントの削除に失敗しました');
    }
  };

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-bold">口コミ ({comments.length}件)</h3>

      {session && (
        <form onSubmit={handleSubmit} className="space-y-2">
          <textarea
            className="textarea textarea-bordered w-full"
            placeholder="口コミを書く..."
            value={body}
            onChange={(e) => setBody(e.target.value)}
            rows={3}
          />
          <button
            type="submit"
            className="btn btn-primary btn-sm"
            disabled={submitting || !body.trim()}
          >
            {submitting ? '投稿中...' : '投稿する'}
          </button>
        </form>
      )}

      {!session && (
        <p className="text-sm text-gray-500">
          口コミを投稿するにはログインが必要です
        </p>
      )}

      <div className="space-y-3">
        {comments.map((comment) => (
          <div key={comment.id} className="card bg-base-200 p-4">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm font-semibold">{comment.user.name}</p>
                <p className="mt-1">{comment.body}</p>
                <p className="mt-1 text-xs text-gray-500">
                  {new Date(comment.created_at).toLocaleDateString('ja-JP')}
                </p>
              </div>
              {comment.own && (
                <button
                  className="btn btn-ghost btn-xs text-error"
                  onClick={() => handleDelete(comment.id)}
                >
                  削除
                </button>
              )}
            </div>
          </div>
        ))}
        {comments.length === 0 && (
          <p className="text-center text-sm text-gray-500">
            まだ口コミはありません
          </p>
        )}
      </div>
    </div>
  );
}
