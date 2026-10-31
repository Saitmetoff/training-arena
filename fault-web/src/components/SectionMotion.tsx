'use client';
import {useEffect} from 'react';
import {MOTION} from '@/lib/motion';
// Progressive enhancement: core text never starts hidden, and repeated scrolling cannot restart motion.
export default function SectionMotion(){
 useEffect(()=>{
  const query=matchMedia('(prefers-reduced-motion: reduce)'),animations:Animation[]=[];
  const stop=()=>{if(query.matches)animations.forEach(animation=>animation.cancel());};
  if(query.matches)return;
  const observer=new IntersectionObserver(entries=>{for(const entry of entries){if(!entry.isIntersecting)continue;observer.unobserve(entry.target);if(query.matches)continue;const items=entry.target.querySelectorAll('.process-list li');items.forEach((item,i)=>animations.push(item.animate([{transform:'translateY(12px)'},{transform:'translateY(0)'}],{duration:MOTION.enter*1000,delay:i*MOTION.stagger*1000,easing:`cubic-bezier(${MOTION.decelerate.join(',')})`})));
  }},{threshold:.15});
  document.querySelectorAll('.next').forEach(element=>observer.observe(element));query.addEventListener('change',stop);
  return()=>{observer.disconnect();query.removeEventListener('change',stop);animations.forEach(animation=>animation.cancel());};
 },[]);
 return null;
}
