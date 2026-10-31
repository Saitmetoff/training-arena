import {getService} from '@/lib/server/runtime';
import {equalSecret} from '@/lib/server/crypto';
import {respond,failure} from '@/lib/server/http';
export const runtime='nodejs';
export const maxDuration=60;
export async function GET(req:Request){
  const secret=process.env.CRON_SECRET;
  if(!secret||!equalSecret(req.headers.get('authorization')||'',`Bearer ${secret}`))return respond({error:'unauthorized'},401);
  try{const service=await getService();await service.repo.command('maintenance',{});const start=Date.now();for(let i=0;i<10&&Date.now()-start<40_000;i++){const result=await service.dispatch();if(!result.ok)break;}return respond({processed:true});}catch(e){return failure(e);}
}
