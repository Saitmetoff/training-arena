import sharp from 'sharp';
import {mkdir,writeFile,readFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url),{ImageResponse}=require('next/og'),{createElement:h}=require('react');
const regular=await readFile('src/app/fonts/Inter-Regular.ttf'),black=await readFile('src/app/fonts/Inter-Black.ttf');
const stages=[['set',['DO THE','SET.']],['enter',['ENTER YOUR','COUNT.']],['save',['KEEP THE','RECORD.']],['review',['COME BACK','TO IT.']]];
const root='public/media/solo';await mkdir(root,{recursive:true});
for(const [id,lines] of stages){
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="780" height="1040" viewBox="0 0 780 1040"><rect width="780" height="1040" fill="#242729"/><path d="M48 112H732" stroke="#3B4245"/><text x="48" y="78" fill="#B6BDB9" font-family="Arial,sans-serif" font-size="18" letter-spacing="2">FAULT / SOLO PRACTICE</text><path d="M48 330h100" stroke="#D6FF3F" stroke-width="8"/><text x="48" y="455" fill="#F6F7F2" font-family="Arial,sans-serif" font-weight="900" font-size="83" letter-spacing="-3">${lines[0]}</text><text x="48" y="545" fill="#F6F7F2" font-family="Arial,sans-serif" font-weight="900" font-size="83" letter-spacing="-3">${lines[1]}</text><text x="48" y="638" fill="#B6BDB9" font-family="Arial,sans-serif" font-size="20">REAL DEMO MEDIA STILL TO BE RECORDED</text><path d="M48 880H732" stroke="#3B4245"/><text x="48" y="925" fill="#B6BDB9" font-family="Arial,sans-serif" font-size="20">MANUAL ENTRY / SELF-REPORTED</text></svg>`;
 await writeFile(`${root}/${id}.svg`,svg.replaceAll('Arial,sans-serif','Inter,Arial,sans-serif'));
 const text=(content,top,size,color,weight=400)=>h('div',{style:{position:'absolute',left:48,top,fontSize:size,color,fontWeight:weight,letterSpacing:weight===900?-3:0}},content);
 const rule=(top,color,height=1,width=684)=>h('div',{style:{position:'absolute',left:48,top,width,height,background:color}});
 const image=new ImageResponse(h('div',{style:{display:'flex',position:'relative',width:780,height:1040,background:'#242729',fontFamily:'Inter'}},text('FAULT / SOLO PRACTICE',55,18,'#B6BDB9'),rule(112,'#3B4245'),rule(330,'#D6FF3F',8,100),text(lines[0],378,80,'#F6F7F2',900),text(lines[1],468,80,'#F6F7F2',900),text('REAL DEMO MEDIA STILL TO BE RECORDED',617,20,'#B6BDB9'),rule(880,'#3B4245'),text('MANUAL ENTRY / SELF-REPORTED',904,20,'#B6BDB9')),{width:780,height:1040,fonts:[{name:'Inter',data:regular,weight:400},{name:'Inter',data:black,weight:900}]});
 await sharp(Buffer.from(await image.arrayBuffer())).webp({quality:85}).toFile(`${root}/${id}.webp`);
}
console.log('Four typographic placeholder posters exported as WebP and editable SVG; no product footage generated.');
