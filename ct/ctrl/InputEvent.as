package ct.ctrl
{
	import flash.events.Event;
	
	public class InputEvent extends Event
	{
		public static const VECTOR_CLEAR:String="vectorClear";
		
		public function InputEvent( ip:InputTextBox, type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type,bubbles,cancelable);
			inputTextBox = ip;
		}
		
		public var inputTextBox:InputTextBox;
		public var val:int=-1;
	}
}