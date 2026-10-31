'use client';
import {useState} from 'react';
import DemoPlayer from '@/components/DemoPlayer';
export default function MediaStateCheck(){
 const [failed,setFailed]=useState(false),[active,setActive]=useState(true);
 return <><div style={{position:'relative',aspectRatio:'3/4',maxWidth:360}}>{failed?<p role="status">Media failed. Written sequence and poster remain available.</p>:<DemoPlayer source="/qa-missing-video.mp4" poster="/media/solo/set.webp" onFailure={()=>setFailed(true)} active={active}/>}</div><button onClick={()=>setActive(false)}>Leave frame</button><button onClick={()=>{setFailed(false);setActive(true);}}>Retry test</button></>;
}
