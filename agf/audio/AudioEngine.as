package agf.audio
{
	import flash.events.*;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.Timer;

	/**
	* Handle simple Audio playing for games and multimedia applications
	*
	* Optional Fade background sounds in and out
	*   bgChannel : SoundChannel
	*
	* methods for the Audio Player
	*
	*   loadSound( name-id:String, path-to-mp3:String )
	*   playHitSound ( name-id:String, volume:Number (0 to 1), pan:Number(-1 to 1), onComplete:function=null) 
	*   playBgSound ( name-id:String, stopCurrent:Boolean=false, fadeIn:Boolean=false )
	*
	*/
	public class AudioEngine
	{
		public function AudioEngine () {}
		
		private var sounds:Object={};
		private var nextBgLoop:String="";
		private var fadeNextLoop:String="";
		private var currentBgLoop:String="";
		private var bgChannel:SoundChannel;
		private var hitChannel:SoundChannel;
		private var fadeOutTimer:Timer = new Timer(1000/31);
		private var fadeInTimer:Timer = new Timer(1000/31);
		private var fadingOut:Boolean = false;
		private var fadingIn:Boolean = false;
		
		public function loadSound (name:String, path:String) :void 
		{
			if(sounds[name] == null) 
			{
				var ur:URLRequest = new URLRequest(path);
				
				var snd:Sound = new Sound();
				snd.addEventListener(Event.COMPLETE, loadCompleteHandler);
				snd.load(ur);
				
				sounds[name] = snd;
			}
			else
			{
				// Sound already registered 
				// sounds[name]
			}
		}
		
		private function loadCompleteHandler (e:Event) :void {
			
		}
		
		public function playHitSound ( sound:String, vol:Number=1, pan:Number=0 , onComplete:function=null ) :void {
			if(sounds[name] != null ) 
			{
				if(!hitChannel) 
				{
					var snd:Sound = sounds[name] as Sound;
					hitChannel = snd.play();
					
					var st:SoundTransform = new SoundTransform(vol, pan);
					hitChannel.soundTransform = st;
					
					if( onComplete ) hitChannel.addEventListener(Event.SOUND_COMPLETE, onComplete);
				}
			}
		}
		
		public function playBgSound (name:String, stopCurrent:Boolean=false, fadeIn:Boolean=false) :void 
		{
			if(name == currentBgLoop) return;
			
			if(sounds[name] != null ) 
			{
				if(!bgChannel) 
				{
					// start sound the first time
					
					currentBgLoop = name;
					
					var snd:Sound = sounds[name] as Sound;
					
					bgChannel = snd.play();
					bgChannel.addEventListener(Event.SOUND_COMPLETE, loop);
					
					if(fadeIn) {
						bgChannel.soundTransform = new SoundTransform(0);
						fadingIn = true;
						fadeInTimer.addEventListener( TimerEvent.TIMER, fadeFirstInHandler );
						fadeInTimer.start();
					}
					
				}
				else
				{
					if(stopCurrent) 
					{
						// fade current sound out and play next
						fadingOut = true;
						fadeNextLoop = name;
						
						fadeOutTimer.addEventListener(  TimerEvent.TIMER, fadeOutHandler );
						fadeOutTimer.start();
						
					}else{
						// play next loop on loop-finish
						nextBgLoop = name;
					}
					
				}
				
			}
		}
		
		private function loop (e:Event) :void {
			if( nextBgLoop != "") {
				currentBgLoop = nextBgLoop;
				nextBgLoop = "";
			}
			
			var snd:Sound = sounds[currentBgLoop] as Sound;
			if(snd) {
				bgChannel = snd.play();
				bgChannel.addEventListener(Event.SOUND_COMPLETE, loop);
			}
		}
		private function fadeFirstInHandler (e:Event) :void {
			if(bgChannel) {
				if(bgChannel.soundTransform.volume < 0.95) {
					
					var st:SoundTransform = new SoundTransform( bgChannel.soundTransform.volume + 0.03 );
					bgChannel.soundTransform = st;
					
				}else{
					fadeInTimer.stop();
					fadeInTimer.removeEventListener(TimerEvent.TIMER, fadeFirstInHandler);
					fadingIn = false;
				}
			}
		}
		
		private function fadeOutHandler (e:Event) :void 
		{
			if(bgChannel) {
				if(bgChannel.soundTransform.volume > 0.05) {
					
					var st:SoundTransform = new SoundTransform( bgChannel.soundTransform.volume - 0.05 );
					bgChannel.soundTransform = st;
					
				}else{
					fadeOutTimer.stop();
					fadeOutTimer.removeEventListener(TimerEvent.TIMER,fadeOutHandler);
					bgChannel.stop();
					bgChannel = null;
					playBgSound(fadeNextLoop);
					fadeNextLoop = "";
					fadingOut = false;
				}
			}
		}
		
	}
}