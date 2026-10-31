import tokens from './motion-tokens.json';
const seconds=(value:string)=>parseFloat(value)/1000;
export const MOTION={micro:seconds(tokens.motion.duration['short-3'].$value),enter:seconds(tokens.motion.duration['medium-1'].$value),frame:seconds(tokens.motion.duration['medium-4'].$value),cut:seconds(tokens.motion.duration.cut.$value),stagger:seconds(tokens.motion.sequencing.small.$value),standard:tokens.motion.easing.standard.$value as [number,number,number,number],decelerate:tokens.motion.easing.enter.$value as [number,number,number,number]};
