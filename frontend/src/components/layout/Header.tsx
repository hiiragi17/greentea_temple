'use client';

import Link from 'next/link';
import { useSession, signIn, signOut } from 'next-auth/react';
import { FiMenu, FiX } from 'react-icons/fi';
import { useState } from 'react';

export default function Header() {
  const { data: session } = useSession();
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="navbar bg-green-700 text-white shadow-lg">
      <div className="container mx-auto flex items-center justify-between px-4">
        <Link href="/" className="text-xl font-bold">
          抹茶と神社。
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden items-center gap-4 md:flex">
          <Link href="/greenteas" className="hover:text-green-200">
            抹茶店一覧
          </Link>
          <Link href="/temples" className="hover:text-green-200">
            神社一覧
          </Link>
          <Link href="/nearby" className="hover:text-green-200">
            現在地検索
          </Link>
          {session ? (
            <div className="dropdown dropdown-end">
              <label tabIndex={0} className="btn btn-ghost btn-sm">
                {session.user?.name || 'ユーザー'}
              </label>
              <ul
                tabIndex={0}
                className="dropdown-content menu rounded-box z-50 w-52 bg-white p-2 text-gray-800 shadow"
              >
                <li>
                  <Link href="/mypage/greentea-likes">お気に入り抹茶店</Link>
                </li>
                <li>
                  <Link href="/mypage/temple-likes">お気に入り神社</Link>
                </li>
                <li>
                  <button onClick={() => signOut()}>ログアウト</button>
                </li>
              </ul>
            </div>
          ) : (
            <button
              onClick={() => signIn()}
              className="btn btn-outline btn-sm text-white hover:bg-green-600"
            >
              ログイン
            </button>
          )}
        </nav>

        {/* Mobile Menu Toggle */}
        <button
          className="btn btn-ghost md:hidden"
          onClick={() => setMenuOpen(!menuOpen)}
        >
          {menuOpen ? <FiX size={24} /> : <FiMenu size={24} />}
        </button>
      </div>

      {/* Mobile Navigation */}
      {menuOpen && (
        <nav className="bg-green-800 pb-4 md:hidden">
          <ul className="menu w-full">
            <li>
              <Link
                href="/greenteas"
                className="text-white"
                onClick={() => setMenuOpen(false)}
              >
                抹茶店一覧
              </Link>
            </li>
            <li>
              <Link
                href="/temples"
                className="text-white"
                onClick={() => setMenuOpen(false)}
              >
                神社一覧
              </Link>
            </li>
            <li>
              <Link
                href="/nearby"
                className="text-white"
                onClick={() => setMenuOpen(false)}
              >
                現在地検索
              </Link>
            </li>
            {session ? (
              <>
                <li>
                  <Link
                    href="/mypage/greentea-likes"
                    className="text-white"
                    onClick={() => setMenuOpen(false)}
                  >
                    お気に入り抹茶店
                  </Link>
                </li>
                <li>
                  <Link
                    href="/mypage/temple-likes"
                    className="text-white"
                    onClick={() => setMenuOpen(false)}
                  >
                    お気に入り神社
                  </Link>
                </li>
                <li>
                  <button
                    onClick={() => signOut()}
                    className="text-white"
                  >
                    ログアウト
                  </button>
                </li>
              </>
            ) : (
              <li>
                <button onClick={() => signIn()} className="text-white">
                  ログイン
                </button>
              </li>
            )}
          </ul>
        </nav>
      )}
    </header>
  );
}
