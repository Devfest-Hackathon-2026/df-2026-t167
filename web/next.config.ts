import type { NextConfig } from "next";

// ブラウザは同じオリジンの /api を呼び、Next.js が API_ORIGIN（Cloud Run）へ転送する。CORS は不要。
const apiOrigin = process.env.API_ORIGIN;
if (!apiOrigin) throw new Error("API_ORIGIN が未設定です（ローカルは .env.local、App Hosting は apphosting.<環境名>.yaml）");

const nextConfig: NextConfig = {
  async rewrites() {
    return [{ source: "/api/:path*", destination: `${apiOrigin}/:path*` }];
  },
};

export default nextConfig;
