import type { Metadata } from 'next';
import './globals.css';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import Providers from '@/components/layout/Providers';

export const metadata: Metadata = {
  title: {
    default: '抹茶と神社。| 京都の抹茶スイーツ×神社巡り',
    template: '%s | 抹茶と神社。',
  },
  description:
    '京都の抹茶スイーツが楽しめるお店と、近くの神社を一緒に探せるWebサービスです。',
  openGraph: {
    title: '抹茶と神社。',
    description: '京都の抹茶スイーツ×神社巡り',
    locale: 'ja_JP',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja" data-theme="emerald">
      <body className="flex min-h-screen flex-col antialiased">
        <Providers>
          <Header />
          <main className="flex-1">{children}</main>
          <Footer />
        </Providers>
      </body>
    </html>
  );
}
