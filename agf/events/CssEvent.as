package agf.events
{
	import flash.events.Event;
	
	public class CssEvent extends Event
	{
		public static const FILES_LOADED:String = "files-loaded";
		public static const STATE_CHANGE:String = "state-change";
		
		public function CssEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		
	}
}