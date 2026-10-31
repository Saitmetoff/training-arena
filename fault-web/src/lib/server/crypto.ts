import {createHash,randomBytes,createCipheriv,createDecipheriv,createHmac,timingSafeEqual} from 'node:crypto';
export const newToken=()=>randomBytes(32).toString('hex');
export const digest=(token:string)=>createHash('sha256').update(token).digest('hex');
export function seal(payload:unknown,key:string):string {
  const bytes=Buffer.from(key,'hex'); if(bytes.length!==32)throw new Error('encryption_configuration');
  const iv=randomBytes(12);const cipher=createCipheriv('aes-256-gcm',bytes,iv);
  const ciphertext=Buffer.concat([cipher.update(JSON.stringify(payload),'utf8'),cipher.final()]);
  return [iv.toString('hex'),cipher.getAuthTag().toString('hex'),ciphertext.toString('hex')].join('.');
}
export function unseal<T>(encrypted:string,key:string):T {
  const [iv,tag,body]=encrypted.split('.');const cipher=createDecipheriv('aes-256-gcm',Buffer.from(key,'hex'),Buffer.from(iv,'hex'));
  cipher.setAuthTag(Buffer.from(tag,'hex'));
  return JSON.parse(Buffer.concat([cipher.update(Buffer.from(body,'hex')),cipher.final()]).toString('utf8')) as T;
}
export const privateBucket=(value:string,key:string)=>createHmac('sha256',key).update(value).digest('hex');
export function equalSecret(actual:string,expected:string):boolean {
  const a=Buffer.from(actual),b=Buffer.from(expected);return a.length===b.length&&timingSafeEqual(a,b);
}
