'use client';
import {useEffect,useRef,useState} from 'react';
import {useAttribution} from './Attribution';
export default function DemoPlayer({source,poster,onFailure,active=true}:{source:string;poster:string;onFailure:()=>void;active?:boolean}){
 const video=useRef<HTMLVideoElement>(null),started=useRef(false),analytics=useAttribution();
 const [loading,setLoading]=useState(false);
 useEffect(()=>{const element=video.current;if(!active)element?.pause();return()=>element?.pause();},[active]);
 return <><video ref={video} className="sequence-video" controls playsInline preload="none" poster={poster} aria-label="Solo push-up development demonstration" onWaiting={()=>setLoading(true)} onPlaying={()=>{setLoading(false);if(!started.current){started.current=true;analytics.capture('demo_play');}}} onCanPlay={()=>setLoading(false)} onPause={()=>setLoading(false)} onError={onFailure}>
  <source src={source} type="video/mp4"/>
  <track src="/media/solo/solo-demo.vtt" kind="captions" srcLang="en" label="English" default/>
  Your browser cannot play this video. <a href={source}>Download the demonstration</a>.
 </video>{loading&&<p className="media-feedback" role="status">Loading video. The written sequence remains available below.</p>}</>;
}
