import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: '利用規約',
};

export default function TermsPage() {
  return (
    <div className="container mx-auto max-w-3xl px-4 py-8">
      <h1 className="mb-8 text-2xl font-bold">利用規約</h1>

      <div className="prose max-w-none">
        <h2>第1条（適用）</h2>
        <p>
          本規約は、本サービス「抹茶と神社。」（以下「本サービス」）の利用条件を定めるものです。
          利用者の皆さまには、本規約に従って本サービスをご利用いただきます。
        </p>

        <h2>第2条（利用登録）</h2>
        <p>
          登録希望者が本規約に同意の上、所定の方法によって利用登録を申請し、
          これを承認することによって、利用登録が完了するものとします。
        </p>

        <h2>第3条（禁止事項）</h2>
        <p>利用者は、以下の行為をしてはなりません。</p>
        <ul>
          <li>法令または公序良俗に違反する行為</li>
          <li>犯罪行為に関連する行為</li>
          <li>本サービスの運営を妨害する行為</li>
          <li>他の利用者に不利益、損害を与える行為</li>
          <li>不正アクセスをし、またはこれを試みる行為</li>
        </ul>

        <h2>第4条（免責事項）</h2>
        <p>
          本サービスに掲載されている情報の正確性については万全を期していますが、
          利用者が本サービスの情報を用いて行う一切の行為について、
          一切の責任を負わないものとします。
        </p>
      </div>
    </div>
  );
}
