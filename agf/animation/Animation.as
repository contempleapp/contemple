package agf.animation
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	import agf.tools.Console;
	
	public class Animation extends Sprite
	{
		public function Animation () {}
		
		/**
		* Animate multiple properties of a object
		* target: any object
		* args: { alpha:0.35, x:200, y:200, scaleX:1.618 ... }
		* duration
		* easeFunc
		*/
		public function run ( target:Object, args:Object, duration:int=1000, easeFunc:Function=null ) :void
		{
			if( !stage ) {
				Console.log( "Error: Animation have to be added to the Stage.");
				return;
			}
			
			_target = target;
			_args = args;
			_duration = duration;
			_easeFunc = easeFunc;
			
			props = new Vector.<String>();
			anims = new Vector.<IChannel>();
			
			if( _target )
			{
				var type:String;
				for( var n:String in args ) {
					if( _target[ n ] != undefined ) {
						type = typeof( _target[n] );
						if( type == "number" ) {
							props.push(n);
							anims.push( new MotionTransition( _target[n], args[n], _duration, _easeFunc ) );
						}
					}
				}
				
				startTime = getTimer();
				addEventListener( Event.ENTER_FRAME, frameHandler );
			}
		} 
		public var loop:Boolean = false;
		
		private var _target:Object;
		private var _args:Object;
		private var _duration:Number;
		private var _easeFunc:Function;
		
		private var props:Vector.<String>;
		private var anims:Vector.<IChannel>;
		private var startTime:int = 0;
		
		private function frameHandler (e:Event) :void
		{
			if( _target && props && anims )
			{
				var t:int = getTimer() - startTime;
				if( t >= _duration ) {
					if( !loop ) {
						dispatchEvent( new Event( Event.COMPLETE ) );
						removeEventListener( Event.ENTER_FRAME, frameHandler );
						t = _duration;
					}else{
						dispatchEvent( new Event( "loop" ) );
						startTime = getTimer();
						t = 1;
					}
				}
				var L:int = props.length;
				for(var i:int = 0; i < L; i++) {
					_target[ props[i] ] = anims[i].getValue(t);
				}
			}
		}
		
	}
	
}