import type {Metadata} from 'next';
import {notFound} from 'next/navigation';
import Landing from '@/components/Landing';
export const metadata:Metadata={title:'Fault — confirmation-first copy preview',robots:{index:false,follow:false}};
export const dynamic='force-dynamic';
export default function Page(){
 if(!['development','preview'].includes(process.env.FAULT_ENVIRONMENT||'')||process.env.VERCEL_ENV==='production')notFound();
 return <Landing confirmationFirst/>;
}
