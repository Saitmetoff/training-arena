'use client';
import {useEffect,useState,type CSSProperties} from 'react';
import {AnimatePresence,useIsPresent,useReducedMotion} from 'motion/react';
import * as m from 'motion/react-m';
import media from '@/lib/demo-media.json';
import {MOTION} from '@/lib/motion';
import DemoPlayer from './DemoPlayer';
type Stage=typeof media.stages[number];
function Frame({stage,mobile,reduce}:{stage:Stage;mobile:boolean;reduce:boolean}){
 const present=useIsPresent();
 const source=media.approved&&media.build&&media.device&&media.rights&&media.evidenceTake?stage.source as string|null:null;
 const [failed,setFailed]=useState(false),[posterFailed,setPosterFailed]=useState(false);
 return <m.div className="sequence-frame" aria-hidden={!present} data-present={present} initial={reduce?false:{opacity:0,x:mobile?0:24}} animate={{opacity:1,x:0}} exit={reduce?{opacity:1}:{opacity:0,x:mobile?0:-24}} transition={{duration:reduce?MOTION.cut:mobile?MOTION.micro:MOTION.frame,ease:MOTION.standard}} style={{'--crop-desktop':stage.crop.desktop,'--crop-mobile':stage.crop.mobile} as CSSProperties}>
  {source&&!failed?(stage.kind==='video'?<DemoPlayer source={source} poster={stage.poster} onFailure={()=>setFailed(true)} active={present}/>:<img src={source} className="sequence-source" alt={stage.title} onError={()=>setFailed(true)}/>):posterFailed?<div className="poster-fallback"><p className="media-title">{stage.title}</p><p>Poster unavailable. Demo media is still pending.</p></div>:<img className="sequence-poster" src={stage.poster} width={780} height={1040} alt={`Illustrative poster: ${stage.title} No product footage or screenshot.`} onError={()=>setPosterFailed(true)} fetchPriority={stage.id==='set'?'high':'auto'}/>}
  {failed&&<button className="media-retry" onClick={()=>setFailed(false)} type="button">Retry media</button>}
  <span className="sequence-disclosure">{failed?'Media unavailable · poster shown':source?'Development build · self-reported':'Illustrative poster · demo media pending'}</span>
 </m.div>;
}
export default function ProductSequence(){
 const [index,setIndex]=useState(0),[mobile,setMobile]=useState(true);
 const reduce=useReducedMotion()??true;
 useEffect(()=>{const query=matchMedia('(min-width:1100px)');const update=()=>setMobile(!query.matches);update();query.addEventListener('change',update);return()=>query.removeEventListener('change',update);},[]);
 const stage=media.stages[index];
 return <section className="product-sequence" aria-label="From effort to record">
  <div className="sequence-heading"><p className="eyebrow">FROM EFFORT TO RECORD</p><span className="sequence-kind">SOLO / SELF-REPORTED</span></div>
  <div className="sequence-window"><AnimatePresence initial={false} mode="sync"><Frame key={stage.id} stage={stage} mobile={mobile} reduce={reduce}/></AnimatePresence></div>
  <div className="sequence-controls" aria-label="Choose a demonstration step">{media.stages.map((item,i)=><button key={item.id} type="button" aria-pressed={i===index} aria-controls="sequence-caption" onClick={()=>setIndex(i)}><span className="sequence-step" aria-hidden="true">0{i+1}</span>{item.label}</button>)}</div>
  <p className="sequence-caption" id="sequence-caption" role="status" aria-live="polite" aria-atomic="true">{stage.caption}</p>
  <details className="sequence-transcript"><summary>Read the full demonstration plan</summary><ol>{media.stages.map(item=><li key={item.id}><strong>{item.title}</strong> {item.caption}</li>)}</ol><p>This is a poster-based interaction. It does not demonstrate a working app, camera counting or a completed battle.</p></details>
 </section>;
}
