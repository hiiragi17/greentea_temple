import type { NextAuthOptions } from 'next-auth';

export const authOptions: NextAuthOptions = {
  providers: [
    {
      id: 'twitter',
      name: 'Twitter',
      type: 'oauth',
      authorization: {
        url: 'https://twitter.com/i/oauth2/authorize',
        params: { scope: 'tweet.read users.read offline.access' },
      },
      token: 'https://api.twitter.com/2/oauth2/token',
      userinfo: 'https://api.twitter.com/2/users/me',
      clientId: process.env.TWITTER_CLIENT_ID,
      clientSecret: process.env.TWITTER_CLIENT_SECRET,
      profile(profile) {
        return {
          id: profile.data.id,
          name: profile.data.name,
          image: profile.data.profile_image_url,
        };
      },
    },
    {
      id: 'line',
      name: 'LINE',
      type: 'oauth',
      authorization: {
        url: 'https://access.line.me/oauth2/v2.1/authorize',
        params: { scope: 'profile openid' },
      },
      token: 'https://api.line.me/oauth2/v2.1/token',
      userinfo: 'https://api.line.me/v2/profile',
      clientId: process.env.LINE_CHANNEL_ID,
      clientSecret: process.env.LINE_CHANNEL_SECRET,
      profile(profile) {
        return {
          id: profile.userId,
          name: profile.displayName,
          image: profile.pictureUrl,
        };
      },
    },
  ],
  callbacks: {
    async jwt({ token, account, profile }) {
      if (account && profile) {
        // OAuth認証成功時にRails APIにトークンを要求
        try {
          const res = await fetch(
            `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001'}/api/v1/auth/${account.provider}`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                code: account.access_token,
                uid: profile.sub || (profile as Record<string, unknown>).userId || account.providerAccountId,
                name: (profile as Record<string, unknown>).name || (profile as Record<string, unknown>).displayName || 'ユーザー',
              }),
            },
          );
          if (res.ok) {
            const data = await res.json();
            token.apiToken = data.data.token;
            token.userId = data.data.user.id;
            token.userName = data.data.user.name;
            token.userRole = data.data.user.role;
          }
        } catch {
          // Rails APIが利用不可の場合は無視
        }
      }
      return token;
    },
    async session({ session, token }) {
      if (token) {
        session.apiToken = token.apiToken as string;
        session.user = {
          ...session.user,
          id: token.userId as number,
          name: token.userName as string,
          role: token.userRole as string,
        };
      }
      return session;
    },
  },
  pages: {
    signIn: '/auth/login',
  },
  secret: process.env.NEXTAUTH_SECRET,
};
