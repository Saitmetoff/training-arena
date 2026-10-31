import {getService} from '@/lib/server/runtime';
import {equalSecret} from '@/lib/server/crypto';
import {respond,failure} from '@/lib/server/http';
export const runtime='nodejs';
export async function POST(req:Request) {
  const secret=process.env.FAULT_DISPATCH_SECRET;
  if(!secret||!equalSecret(req.headers.get('authorization')||'',`Bearer ${secret}`))return respond({error:'unauthorized'},401);
  try {const service=await getService();await service.repo.command('maintenance',{});for(let i=0;i<10;i++)await service.dispatch();return respond({processed:true,counts:await service.repo.command('counts',{})});}catch(e){return failure(e);}
}
