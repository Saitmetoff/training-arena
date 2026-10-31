import Narrative from '@/components/Narrative';
import AttributionProvider from '@/components/Attribution';
import SignupForm from '@/components/SignupForm';
import ShareButton from '@/components/ShareButton';
import ProductSequence from '@/components/ProductSequence';
import SectionMotion from '@/components/SectionMotion';
import WebVitals from '@/components/WebVitals';
import MotionProvider from '@/components/MotionProvider';
export default function Landing({confirmationFirst=false}:{confirmationFirst?:boolean}) {
 return <MotionProvider><AttributionProvider><WebVitals/><p className="preview-banner">Development preview · permitted test signups only{process.env.FAULT_LOCAL_TEST_MODE==='true'?' · email delivery is simulated locally':''}.{confirmationFirst?' Confirmation-first copy pilot; not a live experiment.':''}</p><Narrative signup={<SignupForm confirmationFirst={confirmationFirst}/>} finalSignup={<SignupForm confirmationFirst={confirmationFirst}/>} share={<ShareButton/>} demo={<ProductSequence/>}/><SectionMotion/></AttributionProvider></MotionProvider>;
}
