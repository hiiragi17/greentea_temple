'use client';

import type { PaginationMeta } from '@/types';

interface PaginationProps {
  meta: PaginationMeta;
  onPageChange: (page: number) => void;
}

export default function Pagination({ meta, onPageChange }: PaginationProps) {
  const { current_page, total_pages } = meta;

  if (total_pages <= 1) return null;

  const pages: number[] = [];
  const start = Math.max(1, current_page - 2);
  const end = Math.min(total_pages, current_page + 2);

  for (let i = start; i <= end; i++) {
    pages.push(i);
  }

  return (
    <div className="flex justify-center gap-1">
      <button
        className="btn btn-sm"
        disabled={current_page <= 1}
        onClick={() => onPageChange(current_page - 1)}
      >
        «
      </button>
      {start > 1 && (
        <>
          <button className="btn btn-sm" onClick={() => onPageChange(1)}>
            1
          </button>
          {start > 2 && <span className="btn btn-sm btn-disabled">…</span>}
        </>
      )}
      {pages.map((page) => (
        <button
          key={page}
          className={`btn btn-sm ${page === current_page ? 'btn-primary' : ''}`}
          onClick={() => onPageChange(page)}
        >
          {page}
        </button>
      ))}
      {end < total_pages && (
        <>
          {end < total_pages - 1 && (
            <span className="btn btn-sm btn-disabled">…</span>
          )}
          <button
            className="btn btn-sm"
            onClick={() => onPageChange(total_pages)}
          >
            {total_pages}
          </button>
        </>
      )}
      <button
        className="btn btn-sm"
        disabled={current_page >= total_pages}
        onClick={() => onPageChange(current_page + 1)}
      >
        »
      </button>
    </div>
  );
}
