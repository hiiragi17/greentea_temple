import 'next-auth';

declare module 'next-auth' {
  interface Session {
    apiToken?: string;
    user: {
      id?: number;
      name?: string | null;
      email?: string | null;
      image?: string | null;
      role?: string;
    };
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    apiToken?: string;
    userId?: number;
    userName?: string;
    userRole?: string;
  }
}
