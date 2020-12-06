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
		
		public var loop:Boolean = false;
		
		public function stop () :void
		{
			removeEventListener( Event.ENTER_FRAME, frameHandler );
			if( props ) {
				props = null;
			}
			if( delays ) {
				delays = null;
			}
			if( anims ) {
				anims = null;
			}
		}
		
		/**
		* Animate multiple properties of a object
		* target: any object
		* args: { alpha:0.35, x:200, y:200, scaleX:1.618 ... }
		* duration
		* easeFunc
		*/
		
		public function run ( target:Object, args:Object, duration:int=1000, easeFunc:Function=null, delay:int=0 ) :void
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
			delays = new Vector.<int>();
			anims = new Vector.<IChannel>();
			var mt:MotionTransition;
			var durr:Number;
			var dela:int= 0;
			var maxDuration:Number = _duration + delay;
			
			if( _target )
			{
				var type:String;
				for( var n:String in args )
				{
					if( _target[ n ] != undefined )
					{
						type = typeof( _target[n] );
						
						if( type == "number" )
						{
							props.push(n);
							dela = delay;
							
							if( typeof(args[n]) == "object" )
							{
								// args = { x: { value: 100, duration:1000, delay:250, easeFunc:Regular.easeInOut }, y:100 }
								if( typeof(args[n].delay) != "undefined" ) {
									dela =  Number(args[n].delay);
								}
								if( typeof(args[n].duration) != "undefined" ) { 
									durr = Number(args[n].duration);
									if( durr+dela > maxDuration ) {
										maxDuration = durr+dela;
									}
								}else{
									durr = _duration;
								}
								
								mt = new MotionTransition( _target[n], args[n].value, durr, args[n].easeFunc || _easeFunc )
							}
							else
							{
								mt = new MotionTransition( _target[n], args[n], _duration, _easeFunc );
							}
							
							delays.push( dela );
							anims.push( mt );
						}
					}
				}
				
				_duration = maxDuration;
				startTime = getTimer();
				
				addEventListener( Event.ENTER_FRAME, frameHandler );
			}
		}
		
		private var _target:Object;
		private var _args:Object;
		private var _duration:Number;
		private var _easeFunc:Function;
		
		private var props:Vector.<String>;
		private var delays:Vector.<int>;
		private var anims:Vector.<IChannel>;
		private var startTime:int = 0;
		
		private function frameHandler (e:Event) :void
		{
			if( _target && props && anims )
			{
				var t:int = getTimer() - startTime;
				if( t >= _duration ) {
					if( loop ) {
						dispatchEvent( new Event( "loop" ) );
						startTime = getTimer();
						t = 1;
					}else{
						dispatchEvent( new Event( Event.COMPLETE ) );
						removeEventListener( Event.ENTER_FRAME, frameHandler );
						t = _duration;
					}
				}
				var L:int = props.length;
				for(var i:int = 0; i < L; i++)
				{
					_target[ props[i] ] = anims[i].getValue( t - delays[i] );
				}
			}
		}
		
	}
	
}