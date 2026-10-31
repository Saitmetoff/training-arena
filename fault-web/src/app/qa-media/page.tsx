import {notFound} from 'next/navigation';
import MediaStateCheck from './MediaStateCheck';
export const dynamic='force-dynamic';
export default function Page(){
 if(process.env.FAULT_LOCAL_TEST_MODE!=='true'||process.env.VERCEL)notFound();
 return <main style={{maxWidth:600,margin:'40px auto',padding:24}}><h1>Local media state check</h1><p>Synthetic browser events only. This is not product footage.</p><MediaStateCheck/></main>;
}
