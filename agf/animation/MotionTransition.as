﻿package agf.animation
{
	public class MotionTransition implements IChannel
	{
		public function MotionTransition (valueFrom:Number = 0, valueTo:Number = 1, duration:Number=1000, easeFunction:Function = null) :void {
			this.valueTo = valueTo;
			this.valueFrom = valueFrom;
			this.duration = duration;
			this.easeFunction = easeFunction;
		}
		
		public var valueFrom:Number = 0;
		public var valueTo:Number = 1;
		public var duration:Number = 1000;
		public var easeFunction:Function = null;
		public var loop:Boolean = false;
		
		public function getValue (frame:Number) :Number
		{				
			if(loop)
			{
				if(frame > duration) {
					var fn:Number = frame/duration;
					var f:int = fn;
					frame = fn-f == 0 ? duration : frame - (duration*f);
				}
			}
			
			if(frame >= duration) {
				return valueTo;
			}else if(frame <= 0) {
				return valueFrom;
			}else {
				if(easeFunction == null) 	return (((valueTo - valueFrom) / duration) * frame ) + valueFrom;
				else	return easeFunction( frame, valueFrom, valueTo-valueFrom, duration );
			}
		}
		
		public function storeFrame (keyframe:Number = 1, value:Number = 0, ease_def:*= undefined) :int
		{
			if( typeof( ease_def ) == "function" ) {
				easeFunction = ease_def;
			}
			
			if( keyframe <= 1 ) {
				valueFrom = value;
				return 1;
			}else{
				duration = keyframe;
				valueTo = value;
				return 2;
			}
		}
		
		public function removeFrame (frame:Number = 1) :Boolean {
			return false;
		}
		public function clearFrames () :void {}
	}
}

