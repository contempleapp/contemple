package ct
{
	import flash.events.Event;
	
	public class CTEvent extends Event
	{
		public static const RELOAD:String="reload";
		public static const CANCEL:String="cancel";
		
		public function CTEvent (_obj:Object, type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type,bubbles,cancelable);
			obj = _obj;
		}
		
		public var obj:Object;
	}
}