'use client';
import {createContext,useContext,useState,useEffect,useRef,type ReactNode} from 'react';
import {sanitizeTouch,sanitizeAttribution,type Attribution,type Touch} from '@/lib/contracts';
type Context={attribution:Attribution;visitorId:string|null;enabled:boolean;setEnabled:(value:boolean)=>void;capture:(event:'landing_view'|'demo_play'|'share_click')=>void};
const AnalyticsContext=createContext<Context>({attribution:{first:null,last:null,credit:'direct'},visitorId:null,enabled:false,setEnabled:()=>{},capture:()=>{}});
export const useAttribution=()=>useContext(AnalyticsContext);
export default function AttributionProvider({children}:{children:ReactNode}) {
  const [attribution,setAttribution]=useState<Attribution>({first:null,last:null,credit:'direct'});
  const [visitorId,setVisitorId]=useState<string|null>(null),[enabled,setEnabled]=useState(false);
  const sentLanding=useRef(false);
  useEffect(()=>{
    const params=new URLSearchParams(location.search);
    const candidate=Object.fromEntries(['content_id','creative_id','utm_source','utm_medium','utm_campaign','utm_content'].map(k=>[k,params.get(k)]));
    const touch=sanitizeTouch({...candidate,timestamp:new Date().toISOString()});
    let saved:Attribution={first:null,last:null,credit:'direct'};
    try {saved=sanitizeAttribution(JSON.parse(sessionStorage.getItem('fault.attribution')||'null'));}catch{}
    const updated=sanitizeAttribution({first:saved.first||touch,last:touch||saved.last});setAttribution(updated);
    try{sessionStorage.setItem('fault.attribution',JSON.stringify(updated));}catch{}
  },[]);
  function capture(event:'landing_view'|'demo_play'|'share_click') {
    if(!enabled||!visitorId)return;
    const touch:Touch|null=attribution.last;
    void fetch('/api/events',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({event,visitorId,touch}),keepalive:true}).catch(()=>{});
  }
  function change(value:boolean) {
    setEnabled(value);
    if(value&&!visitorId)setVisitorId(crypto.randomUUID());
  }
  useEffect(()=>{
    if(enabled&&visitorId&&!sentLanding.current){sentLanding.current=true;void fetch('/api/events',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({event:'landing_view',visitorId,touch:attribution.last})}).catch(()=>{});}
  },[enabled,visitorId,attribution.last]);
  return <AnalyticsContext.Provider value={{attribution,visitorId,enabled,setEnabled:change,capture}}>{children}</AnalyticsContext.Provider>;
}
