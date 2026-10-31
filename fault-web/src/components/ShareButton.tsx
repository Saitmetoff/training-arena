'use client';
import {useState} from 'react';
import {useAttribution} from './Attribution';
export default function ShareButton() {
  const [message,setMessage]=useState(''),[busy,setBusy]=useState(false),analytics=useAttribution();
  async function share() {
    if(busy)return;
    setBusy(true);
    const url=new URL('/',location.origin); // Never copy current query, hash, email or token.
    try {if(navigator.share){await navigator.share({title:'Fault',text:'Give your next set a reason.',url:url.href});setMessage('Shared.');}else{await navigator.clipboard.writeText(url.href);setMessage('Link copied.');}analytics.capture('share_click');}catch(error){if(!(error instanceof DOMException&&error.name==='AbortError'))setMessage('Could not share. You can copy the website address.');}finally{setBusy(false);}
  }
  return <div><button type="button" className="secondary-button" onClick={share} disabled={busy} aria-busy={busy}>{busy?'Sharing…':'Share Fault'}</button><p className="helper" role="status" aria-live="polite">{message}</p></div>;
}
