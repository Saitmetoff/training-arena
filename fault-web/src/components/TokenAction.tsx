'use client';
import {useEffect,useRef,useState} from 'react';
import Link from 'next/link';
const messages:Record<string,string>={confirmed:'Your email is confirmed. You’re on the Fault update list. Joining does not give you app access.',used:'This confirmation link has already been used. It cannot create another signup. If you have since unsubscribed, join again with fresh consent.',expired:'This link has expired. Return to the waitlist to request a new confirmation email.',invalid:'This link is invalid or incomplete. Open the complete link from your email.',unsubscribed:'You are unsubscribed from Fault updates. No app account was changed.'};
export default function TokenAction({action}:{action:'confirm'|'unsubscribe'}) {
  const [token,setToken]=useState(''),[state,setState]=useState('ready'),[message,setMessage]=useState('');
  const captured=useRef(false);
  useEffect(()=>{if(captured.current)return;captured.current=true;const value=new URLSearchParams(location.hash.slice(1)).get('token')||'';setToken(value);history.replaceState(null,'',location.pathname);if(!/^[a-f0-9]{64}$/.test(value)){setState('invalid');setMessage(messages.invalid);}},[]);
  async function submit(){setState('loading');try{const r=await fetch(`/api/${action}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token})});const data=await r.json();setState(r.ok?data.state:'error');setMessage(messages[data.state]||data.message||'Please try again.');}catch{setState('error');setMessage('Connection lost. Try again; this action is safe to retry.');}}
  return <main className="page action-page"><p className="eyebrow">FAULT · EMAIL UPDATES</p><h1 className="next-heading">{action==='confirm'?'Confirm your email':'Stop Fault emails'}</h1>
    <p>{action==='confirm'?'One more step to join the update list.':'Confirm below to stop Fault development and launch updates.'}</p>
    {(state==='ready'||state==='loading'||state==='error')&&<button className="primary-button" type="button" onClick={submit} disabled={!token||state==='loading'}>{state==='loading'?'Please wait…':action==='confirm'?'Confirm my email':'Unsubscribe'}</button>}
    <p role="status" aria-live="polite">{message}</p><Link href="/">Return to Fault</Link><noscript><p>Enable JavaScript to confirm this email action. The link is not consumed just by opening it.</p></noscript>
  </main>;
}
