import Link from 'next/link';

export default function Footer() {
  return (
    <footer className="bg-green-800 py-8 text-white">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
          <div>
            <h3 className="mb-2 text-lg font-bold">抹茶と神社。</h3>
            <p className="text-sm text-green-200">
              京都の抹茶スイーツと神社を巡る旅のお供に
            </p>
          </div>
          <div>
            <h4 className="mb-2 font-semibold">メニュー</h4>
            <ul className="space-y-1 text-sm">
              <li>
                <Link href="/greenteas" className="hover:text-green-200">
                  抹茶店一覧
                </Link>
              </li>
              <li>
                <Link href="/temples" className="hover:text-green-200">
                  神社一覧
                </Link>
              </li>
              <li>
                <Link href="/nearby" className="hover:text-green-200">
                  現在地検索
                </Link>
              </li>
            </ul>
          </div>
          <div>
            <h4 className="mb-2 font-semibold">その他</h4>
            <ul className="space-y-1 text-sm">
              <li>
                <Link href="/terms" className="hover:text-green-200">
                  利用規約
                </Link>
              </li>
              <li>
                <Link href="/privacy" className="hover:text-green-200">
                  プライバシーポリシー
                </Link>
              </li>
            </ul>
          </div>
        </div>
        <div className="mt-8 border-t border-green-700 pt-4 text-center text-sm text-green-300">
          &copy; {new Date().getFullYear()} 抹茶と神社。 All rights reserved.
        </div>
      </div>
    </footer>
  );
}
