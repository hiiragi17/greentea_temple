import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'プライバシーポリシー',
};

export default function PrivacyPage() {
  return (
    <div className="container mx-auto max-w-3xl px-4 py-8">
      <h1 className="mb-8 text-2xl font-bold">プライバシーポリシー</h1>

      <div className="prose max-w-none">
        <h2>個人情報の取得について</h2>
        <p>
          本サービス「抹茶と神社。」は、利用者の個人情報を適切に取り扱います。
          SNS認証（Twitter、LINE）によるログイン時に取得する情報は、
          ユーザー名とプロフィール画像のみです。
        </p>

        <h2>個人情報の利用目的</h2>
        <p>取得した個人情報は、以下の目的で利用します。</p>
        <ul>
          <li>本サービスの提供・運営</li>
          <li>利用者のお気に入り・口コミ機能の提供</li>
          <li>サービスの改善・新機能の開発</li>
        </ul>

        <h2>個人情報の第三者提供</h2>
        <p>
          法令に基づく場合を除き、利用者の同意なく個人情報を第三者に提供することはありません。
        </p>

        <h2>位置情報について</h2>
        <p>
          現在地検索機能では、ブラウザのGeolocation
          APIを使用して位置情報を取得します。
          位置情報は検索処理のみに使用し、サーバーに保存することはありません。
        </p>

        <h2>Cookieについて</h2>
        <p>
          本サービスでは、認証状態の管理のためにCookieを使用しています。
          ブラウザの設定でCookieを無効にすることができますが、
          一部の機能が利用できなくなる場合があります。
        </p>
      </div>
    </div>
  );
}
