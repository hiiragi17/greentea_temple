import Link from 'next/link';
import { FiSearch, FiMapPin, FiCoffee } from 'react-icons/fi';
import { BsBuilding } from 'react-icons/bs';

export default function Home() {
  return (
    <div>
      {/* Hero Section */}
      <section className="bg-gradient-to-b from-green-700 to-green-600 py-20 text-white">
        <div className="container mx-auto px-4 text-center">
          <h1 className="mb-4 text-4xl font-bold md:text-5xl">
            抹茶と神社。
          </h1>
          <p className="mb-8 text-lg text-green-100 md:text-xl">
            京都の抹茶スイーツが楽しめるお店と、近くの神社を一緒に探せます
          </p>
          <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
            <Link href="/greenteas" className="btn btn-lg bg-white text-green-700 hover:bg-green-50">
              <FiCoffee size={20} />
              抹茶店を探す
            </Link>
            <Link href="/temples" className="btn btn-lg btn-outline border-white text-white hover:bg-green-800">
              <BsBuilding size={20} />
              神社を探す
            </Link>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16">
        <div className="container mx-auto px-4">
          <h2 className="mb-12 text-center text-2xl font-bold">
            3つの探し方
          </h2>
          <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
            <div className="card bg-base-100 p-6 shadow-md">
              <div className="mb-4 text-center text-4xl text-green-600">
                <FiSearch className="mx-auto" />
              </div>
              <h3 className="mb-2 text-center text-lg font-bold">
                キーワード検索
              </h3>
              <p className="text-center text-gray-600">
                お店の名前やジャンル、エリアからお気に入りの抹茶店・神社を探せます
              </p>
            </div>
            <div className="card bg-base-100 p-6 shadow-md">
              <div className="mb-4 text-center text-4xl text-green-600">
                <FiMapPin className="mx-auto" />
              </div>
              <h3 className="mb-2 text-center text-lg font-bold">
                現在地から探す
              </h3>
              <p className="text-center text-gray-600">
                今いる場所から1.5km以内の抹茶店と神社をマップで表示します
              </p>
            </div>
            <div className="card bg-base-100 p-6 shadow-md">
              <div className="mb-4 text-center text-4xl text-green-600">
                <FiCoffee className="mx-auto" />
              </div>
              <h3 className="mb-2 text-center text-lg font-bold">
                近くのスポット
              </h3>
              <p className="text-center text-gray-600">
                抹茶店の詳細ページから近くの神社、神社の詳細ページから近くの抹茶店がわかります
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-green-50 py-16">
        <div className="container mx-auto px-4 text-center">
          <h2 className="mb-4 text-2xl font-bold">
            さっそく探してみましょう
          </h2>
          <p className="mb-8 text-gray-600">
            京都の抹茶スイーツと神社巡りを楽しみましょう
          </p>
          <Link href="/nearby" className="btn btn-primary btn-lg">
            <FiMapPin size={20} />
            現在地から探す
          </Link>
        </div>
      </section>
    </div>
  );
}
