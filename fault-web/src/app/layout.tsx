import type {Metadata} from 'next';
import localFont from 'next/font/local';
import './globals.css';
import './integration.css';
import './product-sequence.css';
import './polish.css';
import {createSiteMetadata} from '@/lib/metadata';
const inter=localFont({src:[{path:'./fonts/Inter-Regular.woff2',weight:'400'},{path:'./fonts/Inter-Medium.woff2',weight:'500'},{path:'./fonts/Inter-SemiBold.woff2',weight:'600'},{path:'./fonts/Inter-Bold.woff2',weight:'700'},{path:'./fonts/Inter-ExtraBold.woff2',weight:'800'},{path:'./fonts/Inter-Black.woff2',weight:'900'}],variable:'--font-inter',display:'optional',preload:false});
export const metadata:Metadata=createSiteMetadata(process.env.FAULT_SITE_URL||(process.env.VERCEL_URL?`https://${process.env.VERCEL_URL}`:'https://fault.fit'));
export default function Layout({children}:{children:React.ReactNode}) {return <html lang="en" className={inter.variable}><body>{children}</body></html>;}
