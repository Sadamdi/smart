import type { NextConfig } from "next";

// Backend belum punya domain sendiri. Peramban memanggil /backend/... pada alamat web yang sama,
// lalu Next meneruskannya ke BACKEND_ORIGIN (mis. alamat tunnel). Dengan begitu tidak ada masalah
// campuran HTTP dan HTTPS maupun CORS. Ubah BACKEND_ORIGIN lalu deploy ulang bila alamat backend berganti.
const backendOrigin = process.env.BACKEND_ORIGIN;

const nextConfig: NextConfig = {
  async rewrites() {
    if (!backendOrigin) return [];
    return [{ source: "/backend/:path*", destination: `${backendOrigin}/:path*` }];
  },
  cacheComponents: true,
  partialPrefetching: true,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
