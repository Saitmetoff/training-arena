'use client';
import {useId,useState,type FormEvent} from 'react';
import {useReducedMotion} from 'motion/react';
import * as m from 'motion/react-m';
import {useAttribution} from './Attribution';
import {MOTION} from '@/lib/motion';

const BUTTON_LABEL={idle:'Join the waitlist',loading:'Sending…',pending:'Resend confirmation',error:'Try again'} as const;

export default function SignupForm({confirmationFirst=false}:{confirmationFirst?:boolean}) {
  const id=useId(),[state,setState]=useState<'idle'|'loading'|'pending'|'error'>('idle'),[message,setMessage]=useState(''),[invalid,setInvalid]=useState(false);
  const attribution=useAttribution(),reduce=useReducedMotion();
  async function submit(event:FormEvent<HTMLFormElement>) {
    event.preventDefault();if(state==='loading')return;
    const form=event.currentTarget;if(!form.reportValidity())return;
    const data=new FormData(form);setState('loading');setMessage('Sending your confirmation request…');
    try {
      const response=await fetch('/api/waitlist',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:data.get('email'),consent:data.get('consent')==='on',website:data.get('website')||'',attribution:attribution.attribution,analyticsConsent:attribution.enabled,visitorId:attribution.visitorId})});
      const result=await response.json();setState(response.ok?'pending':'error');setMessage(result.message||'We could not complete this request. Please try again.');
    }catch{setState('error');setMessage('Connection lost. Your request may still be pending. Try again with the same address.');}
  }
  return <form className="signup" data-state={state} data-signup-variant={confirmationFirst?'confirmation-first-v1':'control'} aria-busy={state==='loading'} onSubmit={submit} aria-label="Fault waitlist">
    <label className="form-label" htmlFor={`${id}-email`}>Email address</label>
    <div className="field-row"><input id={`${id}-email`} name="email" type="email" autoComplete="email" placeholder="you@example.com" required maxLength={254} aria-invalid={invalid} aria-describedby={`${id}-helper ${id}-status`} onInvalid={()=>setInvalid(true)} onInput={()=>setInvalid(false)} />
    <m.button type="submit" tabIndex={0} whileTap={reduce?undefined:{y:1}} transition={{duration:MOTION.micro,ease:MOTION.standard}} disabled={state==='loading'} aria-busy={state==='loading'}>{confirmationFirst&&state==='idle'?'Send confirmation email':BUTTON_LABEL[state]}</m.button></div>
    <p className="helper" id={`${id}-helper`}>{confirmationFirst?'1. Request an email. 2. Open it and confirm. You join after confirmation. This does not give app access.':'Confirm your email for Fault launch updates. Joining the list does not give you app access.'} Email updates, not a paid subscription. No payment required.</p>
    <label className="consent"><input type="checkbox" name="consent" required/><span>Send me Fault development and launch updates. I can unsubscribe at any time.</span></label>
    <label className="consent"><input type="checkbox" checked={attribution.enabled} onChange={e=>attribution.setEnabled(e.target.checked)}/><span>Allow anonymous website analytics. Optional.</span></label>
    <div className="honeypot" aria-hidden="true"><label>Leave this empty<input name="website" autoComplete="off" tabIndex={-1}/></label></div>
    <p className="form-status" id={`${id}-status`} role="status" aria-live="polite">{state==='error'?'':message}</p>
    {state==='error'?<p className="form-status is-error" role="alert">{message}</p>:null}
    <p className="helper"><a href="/privacy">How we handle your email</a></p>
    <noscript><p>Enable JavaScript to send your confirmation request. The product information remains available above.</p></noscript>
  </form>;
}
