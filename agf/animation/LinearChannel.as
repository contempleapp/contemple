﻿package agf.animation {	import agf.animation.IChannel;	import agf.animation.KeyFrame;		/**	* LinearChannel provides keyframes with linear interpolation	*/	public class LinearChannel implements IChannel 	{		public function LinearChannel () {			clearFrames();		}				/** 		* Read Only, number of all frames in the channel 		*/		public var totalframes:Number;		/** 		* @private		* Use storeFrame, moveKeyFrame and removeKeyFrame methods to modify the keyFrames Array		*/		public var keyFrames:Vector.<KeyFrame>;		/** 		* Set loop to true if you want the envelope to loop after the lastframe		*/		public var loop:Boolean=false;		/**		* @private		*/		protected var keyFrameTable:Object;				/** 		* Delete all keyframes 		*/		public function clearFrames () :void {			totalframes = 0;			keyFrameTable = null;						if(!keyFrames) keyFrames = new Vector.<KeyFrame>();			else keyFrames.splice(0, keyFrames.length);						keyFrameTable = {};			storeFrame(1, 0);		}				public function bake (frameStep:Number=1) :Vector.<Number> {						var cache:Vector.<Number> = new Vector.<Number>;			var L:int = totalframes/frameStep;						if(L > 0) {				var k:Number=1;								for(var i:int=0; i<L; i++) {					cache[i] = getValue(k);					k += frameStep;				}			}						return cache;		}				/** 		* Add or override a Keyframe		* @param	keyframe	the number of the frame		* @param	value		the numeric value at the Keyframe		* @param	ease_def	a function for individual easing		*/		public function storeFrame (keyframe:Number=1, value:Number=0, ease_def:*=undefined) :int {			if(keyframe >= 0) 			{				var kf:KeyFrame;								if(keyFrames.length < 1 || keyframe > totalframes) {					keyFrameTable["k"+keyframe] = keyFrames.push( new KeyFrame(keyframe, value, ease_def) ) - 1;		// push				}				else{					if(keyframe <= 1) {						kf = keyFrames[0];						kf.frame = keyframe;						kf.value = value;						kf.easeFunc = ease_def;					}					else if(typeof (keyFrameTable["k" + keyframe]) == "number") {						kf = keyFrames[keyFrameTable["k" + keyframe]];						kf.frame = keyframe						kf.value = value						kf.easeFunc = ease_def;					}					else{						var l:int = keyFrames.length;						for(var i:int=0; i<l; i++) {							if(keyFrames[i].frame > keyframe) {								// insert new keyframe between 2 keyframes ( slow )								keyFrames.splice(i, 0, new KeyFrame(keyframe, value, ease_def));								buildTable();								break;							}						}					}				}				totalframes = keyFrames[keyFrames.length-1].frame;				return keyFrameTable["k"+keyframe];			}						return -1;		}		/**			* returns the next keyframe after the frame value as index in the keyFrames Array		*/		public function getNextKeyFrame (frame:Number=1) :int {			for(var i:int=0; i<keyFrames.length; i++) {				if( keyFrames[i].frame > frame ) {					return i;				}			}			return -1;		}		/**			* returns the previous keyframe of the frame value as index in the keyFrames Array		*/		public function getPrevKeyFrame (frame:Number=1) :int {			for(var i:int=keyFrames.length-1; i>= 0; i--) {				if( keyFrames[i].frame < frame ) {					return i;				}			}			return -1;		}		/**			* Test if a keyframe is already available		*/		public function hasKeyFrame (frame:Number=1) :Boolean {			return typeof(keyFrameTable["k"+frame]) == "number";		}		/**			* Removes a keyframe if available 		*/		public function removeFrame (frame:Number=1) :Boolean {			if(typeof(keyFrameTable["k"+frame]) == "number") {				return removeKeyFrame(keyFrameTable["k"+frame]);			}			return false;		}				private function removeKeyFrame (kf:int) :Boolean {			var L:int = keyFrames.length;						if(kf > 0 && kf < L) {				delete keyFrameTable["k"+keyFrames[kf].frame];								if(kf == L-1) {					totalframes = keyFrames[L-2].frame;				}				keyFrames.splice(kf, 1);				return true;			}			return false;		}				public function getValue (frame:Number) :Number {						if(loop) {				if(frame > totalframes) {					var fn:Number = frame/totalframes;					var f:int = fn;					frame = fn-f == 0 ? totalframes : frame - (totalframes*f);				}			}						var fi:int;						if(frame >= totalframes) {				fi = keyFrames.length-1;			}else if(frame < 1) {				fi = 0;			}else{								if(typeof(keyFrameTable["k"+frame]) != "number") {					var lndx:int = 0;					for(var i:int=keyFrames.length-1; i>=0; i--) {						if(keyFrames[i].frame < frame) {							lndx = i;							break;						}						}											var lowKey:KeyFrame = keyFrames[lndx];					var hiKey:KeyFrame = keyFrames[lndx+1];										var rv:Number = (((hiKey.value - lowKey.value) / (hiKey.frame - lowKey.frame))*(frame-lowKey.frame))+lowKey.value;										return rv;				} 				else{					fi = keyFrameTable["k"+frame];				}							}						return keyFrames[fi].value;		}				/**			* Moves the keyframe to another frame and optional change the value of the keyframe		* @param 	keyframe	the frame wich should be moved		* @param 	frame		the new frame of the keyframe		* @param 	value		the new value of the keyframe		*/		public function moveKeyFrame (keyframe:Number, frame:Number, value:*=null) :void 		{			if( typeof(keyFrameTable["k" + keyframe]) == "number") {				var id:int = keyFrameTable["k" + keyframe];				var kf:KeyFrame = keyFrames[id];								if(frame != kf.frame) {					removeKeyFrame( id ); 					storeFrame( frame, value, kf.easeFunc );				}else{					if(value != null) kf.value = Number(value);				}			}		}				private function buildTable () :void {			keyFrameTable = {};			var L:int = keyFrames.length;			for(var i:int=0; i<L; i++) {				keyFrameTable["k"+keyFrames[i].frame] = i;			}		}			}}