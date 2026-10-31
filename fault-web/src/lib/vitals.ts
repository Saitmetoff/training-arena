import {isRecord,UUID} from './contracts';
export type Vital={name:'LCP'|'INP'|'CLS';id:string;value:number};
export function safeVital(input:unknown):{visitorId:string;metric:Vital}|null {
  if(!isRecord(input)||Object.keys(input).some(k=>!['visitorId','metric'].includes(k))||typeof input.visitorId!=='string'||!UUID.test(input.visitorId)||!isRecord(input.metric))return null;
  const m=input.metric;
  if(Object.keys(m).some(k=>!['name','id','value'].includes(k))||!['LCP','INP','CLS'].includes(m.name as string)||typeof m.id!=='string'||!/^v\d+-\d{10,16}-\d{10,16}$/.test(m.id)||typeof m.value!=='number'||!Number.isFinite(m.value)||m.value<0||m.value>(m.name==='CLS'?100:600_000))return null;
  return {visitorId:input.visitorId,metric:{name:m.name as Vital['name'],id:m.id,value:m.value}};
}
