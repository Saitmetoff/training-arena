// SYNTHETIC file headers, not full decoded images or device evidence.
import { assertEquals, assertThrowsCode } from "./assert.ts";
import { decodeAvatar, imageDimensions, AvatarContentType } from "../lib/avatar.ts";
import { mapRpcError } from "../lib/errors.ts";

function b64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes));
}
function png(width: number, height: number): Uint8Array {
  const bytes = new Uint8Array(33);
  bytes.set([0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a,0,0,0,13,73,72,68,82]);
  const view = new DataView(bytes.buffer);
  view.setUint32(16,width); view.setUint32(20,height);
  return bytes;
}
function jpeg(width: number, height: number, progressive = false): Uint8Array {
  return new Uint8Array([0xff,0xd8,0xff,0xe1,0,4,0,0,
    0xff,progressive ? 0xc2 : 0xc0,0,11,8,
    height>>8,height&255,width>>8,width&255,1,1,0x11,0]);
}
function webp(width: number,height: number,kind:string): Uint8Array {
  const size = kind === "VP8L" ? 5 : 10;
  const bytes = new Uint8Array(20+size+(size&1));
  const v = new DataView(bytes.buffer);
  bytes.set(new TextEncoder().encode("RIFF")); v.setUint32(4,bytes.length-8,true);
  bytes.set(new TextEncoder().encode("WEBP"),8);
  bytes.set(new TextEncoder().encode(kind),12); v.setUint32(16,size,true);
  if(kind === "VP8X") {
    for(let i=0;i<3;i++) { bytes[24+i]=(width-1)>>(i*8)&255; bytes[27+i]=(height-1)>>(i*8)&255; }
  } else if(kind === "VP8L") {
    bytes[20]=0x2f; v.setUint32(21,(width-1)|((height-1)<<14),true);
  } else {
    bytes.set([0,0,0,0x9d,1,0x2a],20); v.setUint16(26,width,true); v.setUint16(28,height,true);
  }
  return bytes;
}
const formats: [AvatarContentType,(w:number,h:number)=>Uint8Array][] = [
  ["image/png",png],["image/jpeg",jpeg],["image/jpeg",(w,h)=>jpeg(w,h,true)],
  ...["VP8X","VP8L","VP8 "].map(kind => ["image/webp",(w:number,h:number)=>webp(w,h,kind)] as
    [AvatarContentType,(w:number,h:number)=>Uint8Array]),
];
for(const [type,make] of formats) {
  Deno.test(`SYNTHETIC ${type} dimension header ${make.name}`,()=> {
    assertEquals(imageDimensions(make(1024,1024),type),{width:1024,height:1024});
    assertEquals(decodeAvatar(b64(make(1024,1024)),type).contentType,type);
    assertThrowsCode(()=>decodeAvatar(b64(make(1025,512)),type),"avatar_too_large");
    assertThrowsCode(()=>decodeAvatar(b64(make(512,1025)),type),"avatar_too_large");
    const truncated = make(512,512).subarray(0,12);
    assertThrowsCode(()=>decodeAvatar(b64(truncated),type),"avatar_invalid");
  });
}
Deno.test("SYNTHETIC zero PNG/JPEG and malformed WebP chunks fail",()=> {
  assertThrowsCode(()=>decodeAvatar(b64(png(0,1)),"image/png"),"avatar_invalid");
  assertThrowsCode(()=>decodeAvatar(b64(jpeg(1,0)),"image/jpeg"),"avatar_invalid");
  const bytes=webp(1,1,"VP8X"); new DataView(bytes.buffer).setUint32(16,100,true);
  assertThrowsCode(()=>decodeAvatar(b64(bytes),"image/webp"),"avatar_invalid");
});
Deno.test("analytics AR017 uses the existing rate_limited error envelope",()=> {
  assertEquals(mapRpcError({code:"AR017",message:"analytics exceeds 120 events per hour"}).code,"rate_limited");
});
