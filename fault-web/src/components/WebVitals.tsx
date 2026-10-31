'use client';
import {useCallback,useEffect,useRef} from 'react';
import {useReportWebVitals} from 'next/web-vitals';
import {useAttribution} from './Attribution';
import {safeVital} from '@/lib/vitals';
export default function WebVitals(){
  const {enabled,visitorId}=useAttribution();
  const consent=useRef({enabled:false,visitorId:null as string|null});
  useEffect(()=>{consent.current={enabled,visitorId};},[enabled,visitorId]);
  const report=useCallback<Parameters<typeof useReportWebVitals>[0]>(metric=>{
    const current=consent.current;if(!current.enabled||!current.visitorId)return;
    const value=safeVital({visitorId:current.visitorId,metric:{name:metric.name,id:metric.id,value:metric.value}});
    if(value)void fetch('/api/vitals',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(value),keepalive:true}).catch(()=>{});
  },[]);
  useReportWebVitals(report);
  return null;
}
