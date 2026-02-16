import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="container mx-auto flex min-h-[60vh] flex-col items-center justify-center px-4 py-8 text-center">
      <h1 className="mb-4 text-6xl font-bold text-gray-300">404</h1>
      <h2 className="mb-4 text-2xl font-bold">ページが見つかりません</h2>
      <p className="mb-8 text-gray-600">
        お探しのページは存在しないか、移動した可能性があります。
      </p>
      <Link href="/" className="btn btn-primary">
        トップページに戻る
      </Link>
    </div>
  );
}
