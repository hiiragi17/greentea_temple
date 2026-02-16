'use client';

import { signIn } from 'next-auth/react';
import { FaTwitter, FaLine } from 'react-icons/fa';

export default function LoginPage() {
  return (
    <div className="container mx-auto flex min-h-[60vh] items-center justify-center px-4 py-8">
      <div className="card w-full max-w-md bg-base-100 p-8 shadow-lg">
        <h1 className="mb-6 text-center text-2xl font-bold">ログイン</h1>
        <p className="mb-8 text-center text-gray-600">
          SNSアカウントでログインできます
        </p>

        <div className="space-y-4">
          <button
            onClick={() => signIn('twitter', { callbackUrl: '/' })}
            className="btn btn-block gap-2 bg-[#1DA1F2] text-white hover:bg-[#1a8cd8]"
          >
            <FaTwitter size={20} />
            Twitterでログイン
          </button>

          <button
            onClick={() => signIn('line', { callbackUrl: '/' })}
            className="btn btn-block gap-2 bg-[#06C755] text-white hover:bg-[#05b34c]"
          >
            <FaLine size={20} />
            LINEでログイン
          </button>
        </div>
      </div>
    </div>
  );
}
