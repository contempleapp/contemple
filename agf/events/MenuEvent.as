package agf.events
{
	import flash.events.Event;
	
	public class MenuEvent extends Event
	{
		public function MenuEvent(type:String, name:String="", uid:String="", bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.name = name;
			this.uid = uid;
		}
		public var name:String="";
		public var uid:String="";
	}
}