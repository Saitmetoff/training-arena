import {ImageResponse} from 'next/og';
import {readFile} from 'node:fs/promises';
import {join} from 'node:path';
export const runtime='nodejs';
export async function GET(){
 const font=await readFile(join(process.cwd(),'src/app/fonts/Inter-Black.ttf'));
 return new ImageResponse(<div style={{display:'flex',flexDirection:'column',justifyContent:'space-between',width:'100%',height:'100%',padding:64,background:'#17191A',color:'#F6F7F2',fontFamily:'Inter'}}>
 <div style={{display:'flex',justifyContent:'space-between',fontSize:28}}><span>FAULT</span><span style={{color:'#B6BDB9',fontSize:22}}>IN DEVELOPMENT</span></div>
 <div style={{display:'flex',flexDirection:'column',fontSize:104,letterSpacing:-5,lineHeight:1}}><span>Give your next set</span><span>a reason.</span></div>
 <div style={{display:'flex',justifyContent:'space-between',fontSize:24,color:'#B6BDB9'}}><span>Solo push-ups. Your count. Your record.</span><span style={{color:'#D6FF3F'}}>Android first.</span></div>
 </div>,{width:1200,height:630,fonts:[{name:'Inter',data:font,weight:900}]});
}
