import React,{type CSSProperties} from 'react';
import {Body,Button,Container,Head,Heading,Html,Link,Preview,Text} from 'react-email';

// Review drafts only. No route, sender, campaign or automatic welcome calls this template.
export const GROWTH_DRAFTS={
 welcome:{subject:'You’re confirmed. Welcome to Fault.',preheader:'Give your next set a reason. Android first, still in development.',heading:'Give your next set a reason.',paragraphs:[
  'Thanks for confirming your email. We’ll send the Fault development and launch updates you asked for.',
  'Fault is being built around a simple loop: do a push-up set, enter your own count, save it on your phone, and review your recent sets. Results are self-reported. Android first.',
  'Joining this list does not give app access. There is no confirmed public launch date.'],cta:'Review the development scope'},
 development:{subject:'The set-to-record loop we’re building',preheader:'Manual entry, local history, and what still needs checking.',heading:'Do the set. Keep the record.',paragraphs:[
  'The current implementation lets you enter a push-up count yourself, label it self-reported, and save it on your phone. The history view covers the last seven days; a personal best means best within retained history.',
  'Source and automated checks support that loop. The physical-phone walkthrough and release checks still need to be completed. Camera counting remains under test and is not offered in the current scope.',
  'What would make a saved set useful to you next time? Reply with one thing you would want to compare.'],cta:'Review the development scope'},
 interest:{subject:'Would you try Fault on Android?',preheader:'A question about interest, with no access or launch date promised.',heading:'Would this fit your next set?',paragraphs:[
  'We’re preparing Fault for Android first: solo push-ups, your own rep count, and a record saved on your phone.',
  'If you would want to try that when access is ready, reply INTERESTED and tell us your phone platform. This is a question about interest, not an invitation or reservation of access.',
  'There is no confirmed public launch date. You can unsubscribe whenever you want.'],cta:'Review the development scope'}
} as const;
export type GrowthKind=keyof typeof GROWTH_DRAFTS;
type Props={kind:GrowthKind;siteUrl:string;unsubscribeUrl:string;operatorAddress:string;replyToLabel:string;draftNotice?:boolean};
const text:CSSProperties={fontSize:'16px',lineHeight:'24px',color:'#B6BDB9',margin:'0 0 18px'};
export default function GrowthDraft({kind,siteUrl,unsubscribeUrl,operatorAddress,replyToLabel,draftNotice=false}:Props){
 const copy=GROWTH_DRAFTS[kind];
 return <Html lang="en" dir="ltr"><Head/><Body style={{backgroundColor:'#17191A',margin:0,padding:'24px 0',fontFamily:'Arial, Helvetica, sans-serif'}}><Preview>{copy.preheader}</Preview><Container style={{maxWidth:'560px',padding:'24px',backgroundColor:'#17191A'}}>
  {draftNotice?<Text style={{...text,color:'#D6FF3F'}}>DRAFT FOR REVIEW — sender, operator and links await configuration.</Text>:null}
  <Text style={{...text,color:'#F6F7F2',fontWeight:700,letterSpacing:'2px'}}>FAULT</Text>
  <Heading as="h1" style={{fontSize:'28px',lineHeight:'34px',color:'#F6F7F2',margin:'0 0 24px'}}>{copy.heading}</Heading>
  {copy.paragraphs.map(p=><Text key={p} style={text}>{p}</Text>)}
  <Button href={siteUrl} style={{boxSizing:'border-box',backgroundColor:'#D6FF3F',color:'#17191A',fontSize:'16px',padding:'16px 20px',textDecoration:'none',borderRadius:'8px'}}>{copy.cta}</Button>
  <Text style={{...text,margin:'24px 0 0'}}>Reply to: {replyToLabel}</Text>
  <Text style={text}>You requested Fault development and launch updates. <Link href={unsubscribeUrl} style={{color:'#D6FF3F'}}>Unsubscribe from Fault updates</Link>.</Text>
  <Text style={{...text,fontSize:'14px'}}>{operatorAddress}</Text>
 </Container></Body></Html>;
}
