package agf.events
{
	import flash.events.Event;
	
	public class ShortcutEvent extends Event
	{
		public function ShortcutEvent (type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type,bubbles,cancelable);
		}
		
		public static var SHORTCUT:String = "shortcut";
		
		public var command:Object={};
		public var keyName:String="";
	}
}