import type { NextConfig } from 'next';
const config: NextConfig = {
  poweredByHeader: false,
  async rewrites(){return [
    {source:'/c/:path*',destination:'/legacy/index.html'},
    {source:'/privacy.html',destination:'/legacy/privacy.html'},
    {source:'/support.html',destination:'/legacy/support.html'},
    {source:'/delete-account.html',destination:'/legacy/delete-account.html'}
  ];},
  async headers() { return [{source:'/:path*',headers:[{key:'Referrer-Policy',value:'no-referrer'},{key:'X-Content-Type-Options',value:'nosniff'},{key:'X-Frame-Options',value:'DENY'},{key:'Permissions-Policy',value:'camera=(), microphone=(), geolocation=()'},{key:'X-Robots-Tag',value:'noindex, nofollow'}]}]; }
};
export default config;
