import 'server-only';
import {after} from 'next/server';
import type {WaitlistService} from './service';
import {configured} from './runtime';
export function flushAfterResponse(service:WaitlistService){
  // Persist first. A platform interruption leaves leased/durable jobs recoverable.
  after(async()=>{try{for(let i=0;i<4&&configured();i++){const result=await service.dispatch();if(!result.ok)break;}}catch{/* No payloads or provider errors are logged. Cron/request retry recovers durable work. */}});
}
